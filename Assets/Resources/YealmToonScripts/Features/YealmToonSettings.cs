using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("YealmToon/GlobalSettings")]
public class YealmToonSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter specularThreshold = new ClampedFloatParameter(0.8f, 0f, 1f);
    public FloatRangeParameter brightShadowStepRange = new FloatRangeParameter(new Vector2(0f, 0.2f), -1, 1);


    public bool IsActive()
    {
        return true;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
