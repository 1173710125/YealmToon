using UnityEngine;

public class YealmToonSceneSettings : MonoBehaviour
{
    public Cubemap envCubeMap;
    public float envLightingIntensity;

    [ExecuteAlways]
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Shader.SetGlobalTexture("_EnvCubeMap", envCubeMap);
        Shader.SetGlobalFloat("_EnvLightingIntensity", envLightingIntensity);
    }

    // Update is called once per frame
    private void OnValidate()
    {
        Shader.SetGlobalTexture("_EnvCubeMap", envCubeMap);
        Shader.SetGlobalFloat("_EnvLightingIntensity", envLightingIntensity);
    }

}
