#ifndef PARTICALES_FX
#define PARTICALES_FX
#include "Common.fx"
#include "Material.fx"

static const float scale = 0.5f;

static const float4 g_positions[4] =
{
	float4(scale, scale, 0, 0),
    float4(-scale, scale, 0, 0),
	float4(scale, -scale, 0, 0),
    float4(-scale, -scale, 0, 0),
};

static const float2 g_texcoords[4] =
{
    float2(1, 1),
    float2(0, 1),
    float2(1, 0),    
    float2(0, 0),
};

struct Particle
{
	float3 position;
    float pad0;
    float3 velocity;
	float time;	
};

cbuffer ParticleBasicParameters
{
    float3 EmitterLocation; 
    float ParticleLife;     
    float3 ConsumerLocation;
    float pad0;
    float2 ParticleSize;
    float2 pad1;
    float3 InitialVelocity;    
    float pad2;
    float3 Acceleration;
    float pad3;
};

cbuffer ParticleFrame : register(b1)
{    
    float3 RandomVector;
    float TimeFactors; 
    uint RandomSeed;
    uint NumParticles;     
    float2 Pad;
};

ConsumeStructuredBuffer<Particle> CurrentSimulationState : register(u0);
AppendStructuredBuffer<Particle> NewSimulationState : register(u1);

static const float3 direction[8] =
{
	normalize(float3(1.0f, 1.0f, 1.0f)),
	normalize(float3(-1.0f, 1.0f, 1.0f)),
	normalize(float3(-1.0f, -1.0f, 1.0f)),
	normalize(float3(1.0f, -1.0f, 1.0f)),
	normalize(float3(1.0f, 1.0f, -1.0f)),
	normalize(float3(-1.0f, 1.0f, -1.0f)),
	normalize(float3(-1.0f, -1.0f, -1.0f)),
	normalize(float3(1.0f, -1.0f, -1.0f))
};


[numthreads(8, 1, 1)]
void ParticleInsertCSMAIN(uint3 GroupThreadID : SV_GroupThreadID)
{
	Particle p;

	// Initialize position to the current emitter location
    p.position = EmitterLocation;

	// Initialize direction to a randomly reflected vector
    p.velocity = normalize(reflect(direction[GroupThreadID.x], RandomVector)) * InitialVelocity;

	// Initialize the lifetime of the particle in seconds
	p.time = 0.0f;

	p.pad0 = 0;
	// Append the new particle to the output buffer
    NewSimulationState.Append(p);
}


[numthreads(512, 1, 1)]
void ParticleUpdateCSMAIN(uint3 DispatchThreadID : SV_DispatchThreadID)
{
	// Check for if this thread should run or not.
    uint myID = DispatchThreadID.x + DispatchThreadID.y * 512 + DispatchThreadID.z * 512 * 512;

    if (myID < NumParticles)
    {
		// Get the current particle
        Particle p = CurrentSimulationState.Consume();

		// Calculate the new velocity, accounting for the acceleration from
		// the gravitational force over the current time step.
        p.velocity += Acceleration * TimeFactors;

		// Calculate the new position, accounting for the new velocity value
		// over the current time step.
        p.position += p.velocity * TimeFactors;

		// Update the life time left for the particle.
        p.time = p.time + TimeFactors;

		// Test to see how close the particle is to the black hole, and 
		// don't pass it to the output list if it is too close.
      //  if (r > eventHorizon)
        {
            if (p.time < ParticleLife)
            {
                NewSimulationState.Append(p);
            }
        }
    }
}

//--------------------------------------------------------------------------------
// Inter-stage structures
//--------------------------------------------------------------------------------
struct ParticleVS_INPUT
{
    uint vertexid : SV_VertexID;
};
//--------------------------------------------------------------------------------
struct ParticleGS_INPUT
{
    float3 position : Position;
};
//--------------------------------------------------------------------------------
struct ParticlePS_INPUT
{
    float4 position : SV_Position;
	noperspective
    float2 texcoords : TEXCOORD0;
    float opacity : OPACITY0;
};

StructuredBuffer<Particle> SimulationState;

//--------------------------------------------------------------------------------
ParticleGS_INPUT ParticleVSMAIN(in ParticleVS_INPUT input)
{
	ParticleGS_INPUT output;
    output.position.xyz = SimulationState[input.vertexid].position;
    return output;
}

//--------------------------------------------------------------------------------
[maxvertexcount(4)]
void ParticleGSMAIN(point ParticleGS_INPUT input[1], inout TriangleStream<ParticlePS_INPUT> SpriteStream)
{
    ParticlePS_INPUT output;

    float dist = saturate(length(input[0].position - ConsumerLocation.xyz) / 100.0f);
    float opacity = saturate(1 - dist);

	//// Transform to view space
    float4 viewposition = mul(mul(float4(input[0].position, 1.0f), mWorld), mView);

    // Emit two new triangles
    for (int i = 0; i < 4; i++)
    {
		// Transform to clip space

        output.position = mul(viewposition + g_positions[i] * float4(ParticleSize, 0, 0), mProjection);
        output.texcoords = g_texcoords[i];
        output.opacity = opacity;

        SpriteStream.Append(output);
    }

    SpriteStream.RestartStrip();
}
//--------------------------------------------------------------------------------
float4 ParticlePSMAIN(in ParticlePS_INPUT input) : SV_Target
{
    float4 color = float4(1,1,1,input.opacity);
    if (bHasDiffuseMap)
    {
        color *= texDiffuseMap.Sample(LinearSampler, input.texcoords);        
    }
    return color;
}
//--------------------------------------------------------------------------------

#endif