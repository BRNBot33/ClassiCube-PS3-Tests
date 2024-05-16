#include "aligned_vector.h"
#include "private.h"

PolyList OP_LIST;
PolyList PT_LIST;
PolyList TR_LIST;

/**
 *  FAST_MODE will use invW for all Z coordinates sent to the
 *  GPU.
 *
 *  This will break orthographic mode so default is FALSE
 **/

#define FAST_MODE GL_FALSE

GLboolean AUTOSORT_ENABLED = GL_FALSE;

void APIENTRY glKosInit() {
    TRACE();
    
    GLdcConfig config;
    config.autosort_enabled = GL_FALSE;
    config.fsaa_enabled     = GL_FALSE;

    InitGPU(config.autosort_enabled, config.fsaa_enabled);
    AUTOSORT_ENABLED = config.autosort_enabled;

    _glInitContext();
    _glInitTextures();

    OP_LIST.list_type = GPU_LIST_OP_POLY;
    PT_LIST.list_type = GPU_LIST_PT_POLY;
    TR_LIST.list_type = GPU_LIST_TR_POLY;

    aligned_vector_init(&OP_LIST.vector);
    aligned_vector_init(&PT_LIST.vector);
    aligned_vector_init(&TR_LIST.vector);

    aligned_vector_reserve(&OP_LIST.vector, 1024 * 3);
    aligned_vector_reserve(&PT_LIST.vector,  512 * 3);
    aligned_vector_reserve(&TR_LIST.vector, 1024 * 3);
}


void APIENTRY glKosSwapBuffers() {
    TRACE();
    
    pvr_scene_begin();   
        if(aligned_vector_size(&OP_LIST.vector) > 2) {
            pvr_list_begin(GPU_LIST_OP_POLY);
            SceneListSubmit((Vertex*) aligned_vector_front(&OP_LIST.vector), aligned_vector_size(&OP_LIST.vector));
            pvr_list_finish();
        }

        if(aligned_vector_size(&PT_LIST.vector) > 2) {
            pvr_list_begin(GPU_LIST_PT_POLY);
            SceneListSubmit((Vertex*) aligned_vector_front(&PT_LIST.vector), aligned_vector_size(&PT_LIST.vector));
            pvr_list_finish();
        }

        if(aligned_vector_size(&TR_LIST.vector) > 2) {
            pvr_list_begin(GPU_LIST_TR_POLY);
            SceneListSubmit((Vertex*) aligned_vector_front(&TR_LIST.vector), aligned_vector_size(&TR_LIST.vector));
            pvr_list_finish();
        }        
    pvr_scene_finish();
    
    aligned_vector_clear(&OP_LIST.vector);
    aligned_vector_clear(&PT_LIST.vector);
    aligned_vector_clear(&TR_LIST.vector);

    _glApplyScissor(true);
}
