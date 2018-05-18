#version 330

layout(points) in;
layout(triangle_strip,max_vertices=48) out;

vec4 sg_cameraToClipping(in vec4 hms);			//!	\see sgHelper.sfn

in VertexData {
	vec3 normal_cs;
	vec4 position_hcs;
} v_in[];

in Color {
 vec4 vertexColor;
} c_in[];

out VertexData {
	vec3 normal_cs;
	vec4 position_hcs;
} v_out;

out Color {
 vec4 vertexColor;
} c_out;

const float PI = 3.1415926;
const float minSize = 8.0;
const float maxSize = 32.0;
const int minVertices = 6;
const int maxVertices = 16;

uniform mat4 sg_matrix_clippingToCamera;
//uniform float surfelRadius;
uniform int[4] sg_viewport;

void main(void) {
  vec4 center_cs = vec4(v_in[0].position_hcs.xyz / v_in[0].position_hcs.w, 1.0);
  vec3 normal_cs = v_in[0].normal_cs;
	vec3 tangent_cs = normalize(dot(normal_cs,vec3(0.0,1.0,0.0)) > 0.0 ? cross(normal_cs,vec3(0.0,1.0,0.0)) : cross(normal_cs,vec3(1.0,0.0,0.0)));
	vec3 cotangent_cs = normalize(cross(normal_cs, tangent_cs));

  c_out.vertexColor = c_in[0].vertexColor;
  v_out.normal_cs = normal_cs;
  gl_PointSize = gl_in[0].gl_PointSize;
	
	vec4 viewport = vec4(sg_viewport[0], sg_viewport[1], sg_viewport[2], sg_viewport[3]);
	vec4 pos_clip = sg_cameraToClipping(center_cs);
	pos_clip = vec4(pos_clip.xyz / pos_clip.w, 1.0);
	float rad_clip = gl_PointSize / viewport.z;
	vec4 p2_clip = pos_clip + vec4(rad_clip, 0, 0, 0);
	vec4 p2_cs = sg_matrix_clippingToCamera * p2_clip;
	p2_cs = vec4(p2_cs.xyz / p2_cs.w, 1);
	float surfelRadius = distance(center_cs, p2_cs);
	
  vec4 pre_pos_cs = center_cs + vec4(tangent_cs, 0.0) * surfelRadius;
	float sizeRange = clamp( (gl_in[0].gl_PointSize - minSize) / (maxSize-minSize), 0.0, 1.0);
  int vCount = 6 + int(sizeRange * (maxVertices - minVertices)); 
  
  for(int i=1; i<=vCount; ++i) {
    float ang = 2.0 / vCount * PI * i;
    vec4 cur_pos_cs = center_cs + vec4(tangent_cs * cos(ang) - cotangent_cs * sin(ang), 0.0) * surfelRadius;
        
    // previous position
    v_out.position_hcs = pre_pos_cs;
  	gl_Position = sg_cameraToClipping(pre_pos_cs);
  	EmitVertex();
    
    // center
    v_out.position_hcs = center_cs;
  	gl_Position = gl_in[0].gl_Position;
  	EmitVertex();
    
    // current position
    v_out.position_hcs = cur_pos_cs;
  	gl_Position = sg_cameraToClipping(cur_pos_cs);
  	EmitVertex();
      
  	EndPrimitive();
    pre_pos_cs = cur_pos_cs;
  }
}
