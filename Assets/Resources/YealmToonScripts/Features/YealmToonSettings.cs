using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("YealmToon/GlobalSettings")]
public class YealmToonSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter perspectiveCorrectionIntensity = new ClampedFloatParameter(0f, -10f, 10f);

    public bool IsActive()
    {
        return true;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
