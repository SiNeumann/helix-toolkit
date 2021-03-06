﻿#if NETFX_CORE
using Windows.UI.Xaml;
namespace HelixToolkit.UWP
#else
using System.ComponentModel;
using System.Windows;
namespace HelixToolkit.Wpf.SharpDX
#endif
{
    using Model;
    /// <summary>
    /// Render color by triangle normal
    /// </summary>
    public sealed class NormalVectorMaterial : Material
    {
        protected override MaterialCore OnCreateCore()
        {
            return NormalVectorMaterialCore.Core;
        }
    }
}
