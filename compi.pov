#include "colors.inc"
#include "textures.inc" 
#include "styl.pov"

camera { 
   location <20, 20, 60>  
   look_at <1, 10, 10>  
 }
      
light_source { <-3, 10, -3> White shadowless }

background { color rgb<0.2, 0.4, 0.8>  }
  light_source { <100, 100, -100> color rgb 1 }
  plane {
    y, -10
    pigment { checker color White, color Black scale 10 }
  }                                                          



box { <20, 5, 15>,               
      < 0, 4.3, 1>               
      texture {                  
         pigment { Brown }
      }                          
 }        
 
 
box { <19, -4, 1.3>,               
      < 1, 5, 1>               
      texture {                  
         pigment { Brown }
      }                          
 }
 
 
box { <0.3, 5, 13>,               
      < 1, -10, 1>               
      texture {                  
         pigment { Brown }
      }                          
 }
 
 
box { <19, 5, 13>,               
      < 18.3, -10, 1>               
      texture {                  
         pigment { Brown }
      }                          
 }
 


box { <7, 5.5, 14>,               
      < 17, 5, 9>               
      texture {                  
         pigment { 
          image_map{png "image/Clav1.png" once 
          map_type 0           
          interpolate 2 
          } 

      scale <15, 12.5, 1>
      translate <7, 0, 4>      

                 }
                  finish { 
                    ambient 0.1 
                    diffuse 0.5  
                  }
              }
          }                          
             
             
 
box { <10, 13, 6>,               
      < 11, 5, 5.5>               
      texture {                  
         pigment { Black }
      }                          
 }
 
 
box { <5, 16, 6>,               
      < 16, 8, 5.5>               
      texture {                  
         pigment { Black }
      }                          
 }
 
 box { <4.9, 16, 6>,               
      < 15.9, 8, 5.9>               
      texture {                  
         pigment { 
          image_map{png "image/rab.png" once 
          map_type 0           
          interpolate 2
          } 

      scale <18, 12.5, 1>
      translate <5, 5, 4>      
      rotate <0,0,0>
                 }
                  finish { 
                    ambient 0.3 
                    diffuse 0.7  
                  }
              }
          } 
          
// комп          
box { <6, 0, 3>,               
      < 2, -10, 13>               
      texture {                  
         pigment { 
          image_map{png "image/sis.png" once 
          map_type 0           
          interpolate 2
          } 

      scale <6, 11, 1>
      translate <2, -10, 4>      
      rotate <0,0,0>
                 }
                  finish { 
                    ambient 0.3 
                    diffuse 0.7  
                  }
              }
          }   
         
         
       