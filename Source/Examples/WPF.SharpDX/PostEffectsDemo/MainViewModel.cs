﻿using DemoCore;
using HelixToolkit.Mathematics;
using HelixToolkit.Wpf.SharpDX;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using Media3D = System.Windows.Media.Media3D;
using Point3D = System.Windows.Media.Media3D.Point3D;
using Transform3D = System.Windows.Media.Media3D.Transform3D;
using Vector3D = System.Windows.Media.Media3D.Vector3D;

namespace PostEffectsDemo
{
    public class MainViewModel : BaseViewModel
    {
        public Geometry3D MeshModel1 { private set; get; }
        public Geometry3D MeshModel2 { private set; get; }
        public Geometry3D MeshModel3 { private set; get; }
        public Geometry3D FloorModel { private set; get; }
        public PhongMaterial Material1 { private set; get; } = PhongMaterials.Ruby;
        public PhongMaterial Material2 { private set; get; } = PhongMaterials.Turquoise;
        public PhongMaterial Material3 { private set; get; } = PhongMaterials.Silver;

        public PhongMaterial FloorMaterial { private set; get; } = PhongMaterials.Gray;

        public Transform3D Model1Transform { private set; get; }

        public Transform3D Model2Transform { private set; get; }

        public MainViewModel()
        {
            EffectsManager = new DefaultEffectsManager();
            RenderTechnique = EffectsManager[DefaultRenderTechniqueNames.Blinn];
            // titles
            this.Title = "Post Processing Effects Demo";
            this.SubTitle = "WPF & SharpDX";

            // ----------------------------------------------
            // camera setup
            this.Camera = new PerspectiveCamera { Position = new Point3D(0, -30, 0),
                LookDirection = new Vector3D(0, 30, 0),
                UpDirection = new Vector3D(0, 0, 1) };

            var m1 = Load3ds("suzanne.obj").Select(x => x.Geometry).ToArray();
            MeshModel1 = m1[0];

            var m2 = Load3ds("skeleton.3ds").Select(x => x.Geometry).ToArray();
            MeshModel2 = m2[0];

            Model1Transform = new Media3D.TranslateTransform3D(new Vector3D(7, 0, 0));
            Model2Transform = new Media3D.TranslateTransform3D(new Vector3D(-5, 0, 0));

            var builder = new MeshBuilder();
            builder.AddBox(new Vector3(0, 0, -5), 15, 15, 0.2);
            FloorModel = builder.ToMesh();

            builder = new MeshBuilder();
            builder.AddSphere(new Vector3(0, 0, 0), 1);
            MeshModel3 = builder.ToMesh();
        }

        public List<Object3D> Load3ds(string path)
        {
            if (path.EndsWith(".obj", StringComparison.CurrentCultureIgnoreCase))
            {
                var reader = new ObjReader();
                var list = reader.Read(path);
                return list;
            }
            else if (path.EndsWith(".3ds", StringComparison.CurrentCultureIgnoreCase))
            {
                var reader = new StudioReader();
                var list = reader.Read(path);
                return list;
            }
            else
            {
                return new List<Object3D>();
            }
        }
    }
}
