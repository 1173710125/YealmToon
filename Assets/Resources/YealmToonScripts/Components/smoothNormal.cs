using UnityEditor;
using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;

using UnityEditor;


//UV0是一般texture对应通道
//UV1：unity 存储 烘焙的光照贴图UV
//UV2：unity 存储 实时光照贴图UV
//所以从UV3开始存储额外信息
public enum WRITETYPE
{
    VertexColor=0,
    UV3=1,
    // Texter=2,
}
public class SmoothNormalTools : EditorWindow
{
    // public bool customMesh;
    [MenuItem("Tools/平滑法线工具")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(SmoothNormalTools));//显示现有窗口实例。如果没有，请创建一个。
    }

    
    void OnGUI()
    {
        
        GUILayout.Space(5);
        GUILayout.Label ("1、请在Scene中选择需要平滑法线的物体", EditorStyles.boldLabel);
        // mesh = (MeshFilter)EditorGUILayout.ObjectField(mesh,typeof(MeshFilter),true);
        GUILayout.Space(10);
        
        if(GUILayout.Button("2、平滑选中物体的法线")){//执行平滑
           SmoothNormalPrev();
        }
        
        GUILayout.Space(10);


    }
    public  void SmoothNormalPrev()//Mesh选择器 修改
    {  
        if(Selection.gameObjects==null){//检测是否获取到物体
            Debug.LogError("请选择物体");
            return ;
        }

        foreach(var go in Selection.gameObjects){
            MeshFilter[] meshFilters = go.GetComponentsInChildren<MeshFilter>();
            SkinnedMeshRenderer[] skinMeshRenders = go.GetComponentsInChildren<SkinnedMeshRenderer>();
            Debug.LogWarning("1:" + meshFilters.Length + "2:" + skinMeshRenders.Length);
            foreach (var meshFilter in meshFilters)//遍历两种Mesh 调用平滑法线方法
            {
                Mesh mesh = meshFilter.sharedMesh;
                Vector3 [] averageNormals= AverageNormal(mesh);
                write2mesh(mesh,averageNormals);
            }
            foreach (var skinMeshRender in skinMeshRenders)
            {   
                Mesh mesh = skinMeshRender.sharedMesh;
                Vector3 [] averageNormals= AverageNormal(mesh);
                write2mesh(mesh,averageNormals);
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    public Vector3[] AverageNormal(Mesh mesh)
    {
        
        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
            {
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] =
                    (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]);
            }
        }

        var averageNormals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]].normalized;

            // averageNormals[j] = averageNormals[j].normalized;
        }
       
        return averageNormals;
        
    } 
    
    public void write2mesh(Mesh mesh,Vector3[] averageNormals){
        Vector3[] sm_normals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            Vector3 tangent = new Vector3(mesh.tangents[j].x, mesh.tangents[j].y, mesh.tangents[j].z);
            Vector3 normal = new Vector3(mesh.normals[j].x, mesh.normals[j].y, mesh.normals[j].z);
            Vector3 bitangent = Vector3.Cross(tangent, normal).normalized;

            sm_normals[j] = new Vector3(Vector3.Dot(tangent, averageNormals[j]),
                                    Vector3.Dot(bitangent, averageNormals[j]),
                                    Vector3.Dot(normal, averageNormals[j]));       
        }   
        mesh.SetUVs(3, sm_normals);
        mesh.colors = null;
    }


    public void TraverseDirectory(string path){
        DirectoryInfo directory = new DirectoryInfo(path);
        foreach (FileInfo file in directory.GetFiles("*.mesh")) // 只需要处理mesh格式的文件
        {
            // 获取mesh
            string localpath = file.FullName.Split(new[] { "client\\" }, StringSplitOptions.None)[1];
            UnityEngine.Object mesh = AssetDatabase.LoadAssetAtPath(localpath, typeof(Mesh));
            Mesh _mesh = (Mesh)mesh;

            // 排除不需要平滑法线处理的模型
            if(localpath.Contains("face.mesh")){
                continue;
            }
            Vector3 [] averageNormals= AverageNormal(_mesh);
            write2mesh(_mesh, averageNormals);
        }
        foreach (DirectoryInfo subdirectory in directory.GetDirectories())
        {
            TraverseDirectory(subdirectory.FullName); // 递归调用自身，继续遍历子目录
        }

    }


    public void TraverseDirectory2(string path){
        DirectoryInfo directory = new DirectoryInfo(path);
        foreach (FileInfo file in directory.GetFiles("*.mat")) // 只需要处理mesh格式的文件
        {
            // 获取mat
            string localpath = file.FullName.Split(new[] { "client\\" }, StringSplitOptions.None)[1];
            UnityEngine.Object mat = AssetDatabase.LoadAssetAtPath(localpath, typeof(Material));
            Material _mat = (Material)mat;

            // 针对mainRefine 若存在值小于0.0001，则调整为0.001
            if(_mat.HasProperty("_MainRefine")){
                Vector4 mainRefine = _mat.GetVector("_MainRefine");
                if(mainRefine.z < 0.001f){
                    mainRefine.z = 0.001f;
                    _mat.SetVector("_MainRefine", mainRefine);
                    Debug.LogWarning(localpath);
                }
            }

        }
        foreach (DirectoryInfo subdirectory in directory.GetDirectories())
        {
            TraverseDirectory2(subdirectory.FullName); // 递归调用自身，继续遍历子目录
        }

    }
}