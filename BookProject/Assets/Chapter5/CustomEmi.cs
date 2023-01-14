using UnityEditor;
using UnityEngine;

public class CustomEmi : MonoBehaviour
{
    // The menu item.
    [ContextMenu ("Bake Emi")]
    public void Bake ()
    {

        Material tmpMaterial = this.gameObject.GetComponent<Renderer> ().sharedMaterial;
        tmpMaterial.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;


        // Bake the lightmap.
//        Lightmapping.Bake ();
    }
}