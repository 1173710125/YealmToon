using UnityEngine;

[ExecuteAlways]
public class YealmToonCharacterShading : MonoBehaviour
{
    public Transform HeadBoneTransform;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        foreach (var renderer in GetComponentsInChildren<Renderer>())
        {
            Material[] mats = Application.isPlaying ? renderer.materials : renderer.sharedMaterials;
            foreach (var mat in mats)
            {
                if(mat == null || mat.shader == null)
                    continue;

                mat.SetVector("_FaceFrontDirection", HeadBoneTransform != null ? HeadBoneTransform.forward : transform.forward);
                mat.SetVector("_FaceRightDirection", HeadBoneTransform != null ? HeadBoneTransform.right : transform.right);
            }
        }

    }
}
