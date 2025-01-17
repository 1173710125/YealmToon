using UnityEngine;

public class YealmToonSceneSettings : MonoBehaviour
{
    public float m_envLightingIntensity;
    public Color m_upPartSkyColor;
    public Color m_downPartSkyColor;
    public Color m_undergroundPartSkyColor;

    [ExecuteAlways]
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Shader.SetGlobalFloat("_EnvLightingIntensity", m_envLightingIntensity);
        Shader.SetGlobalColor("_UpPartSkyColor", m_upPartSkyColor);
        Shader.SetGlobalColor("_DownPartSkyColor", m_downPartSkyColor);
        Shader.SetGlobalColor("_UndergroundPartSkyColor", m_undergroundPartSkyColor);
    }

    // Update is called once per frame
    private void OnValidate()
    {
        Shader.SetGlobalFloat("_EnvLightingIntensity", m_envLightingIntensity);
        Shader.SetGlobalColor("_UpPartSkyColor", m_upPartSkyColor);
        Shader.SetGlobalColor("_DownPartSkyColor", m_downPartSkyColor);
        Shader.SetGlobalColor("_UndergroundPartSkyColor", m_undergroundPartSkyColor);
    }

}
