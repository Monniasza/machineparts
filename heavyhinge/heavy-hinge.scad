/* [Common Settings] */
// hinge thickness in mm
hinge_thickness = 16;
// number of segments, odd number recommended
segment_count = 5;
// gap bewteen parts in mm
tolerance = 0.3;
// length of a single segment in mm, total hinge length is segment_count * segment_pitch
segment_pitch = 20;

/* [Odd Segments] */
// width of a segment in mm, total hinge width is 2 * element_width
element_width1 = 24;
// number of screws per segment
screws_per_segment1 = 1;
// screw hole diameter in mm
screw_hole_diameter1 = 3;
// screw head diameter in mm
screw_head_diameter1 = 7;

/* [Even Segments] */
// width of a segment in mm, total hinge width is 2 * element_width
element_width2 = 24;
// number of screws per segment
screws_per_segment2 = 1;
// screw hole diameter in mm
screw_hole_diameter2 = 3;
// screw head diameter in mm
screw_head_diameter2 = 7;

// "base plate" thickness in mm (affects screw pocket depth)
screw_base_thickness = hinge_thickness / 5;
// shaft diameter in mm
shaft_diameter = hinge_thickness / 2;

// -----

wedge_radius = hinge_thickness / 2;
shaft_radius = shaft_diameter / 2;
hinge_resolution = hinge_thickness * 5;
shaft_resolution = shaft_diameter * 5;

module wedge(element_width) {
    wedge_angle = 2 * atan(wedge_radius / element_width);
    tangential_point = [-sin(-wedge_angle) * wedge_radius, cos(-wedge_angle) * wedge_radius];
    linear_extrude(height = segment_pitch - tolerance) {
        union() {
            circle(r = wedge_radius, $fn = hinge_resolution);
            polygon([
                [element_width, -wedge_radius], 
                [0, -wedge_radius], 
                tangential_point
            ]);
        }
    }
}

module screw(screw_hole_diameter, screw_head_diameter){
    screw_resolution = screw_head_diameter * 5;
    union() {
        // screw hole
        translate([0, 0, -0.01]) 
        cylinder(
            h = hinge_thickness, 
            r = screw_hole_diameter / 2, 
            $fn = screw_resolution
        );
        // screw head pocket
        translate([0, 0, screw_base_thickness]) 
        cylinder(
            h = hinge_thickness, 
            r = screw_head_diameter / 2, 
            $fn = screw_resolution
        );
    }
}

module element(screws_per_segment, screw_hole_diameter,screw_head_diameter, element_width, isEven){
    mirror([(isEven ? 1 : 0), 0, 0]) {
        difference() {
            rotate([90, 0, 0]) difference() {
                color([0.8,0.8,0.8]) wedge(element_width);
                if(!isEven) //wedge with shaft hole if odd
                    translate([0, 0, -tolerance / 2])
                    color([0,0,0]) 
                    cylinder(
                        h = segment_pitch, 
                        r = shaft_radius + tolerance, 
                        $fn = shaft_resolution
                    );
            } 
            screw_spacing = element_width / (screws_per_segment + 1);
            for (screw_index = [0 : screws_per_segment - 1]) {
                translate([
                    screw_spacing * (screw_index + 1), 
                    -segment_pitch / 2 + tolerance / 2, 
                    -wedge_radius
                ]) color([0.8,0.8,0.8]) screw(screw_hole_diameter, screw_head_diameter);
            }
        }  
    }
}

// generate segments
for (i = [0 : segment_count - 1]) {
    translate([0, -tolerance / 2 - i * segment_pitch, 0]) {
        isEven = i % 2 == 0;
        if(isEven){
            element(screws_per_segment1, screw_hole_diameter1,screw_head_diameter1, element_width1, true);
        }else{
            element(screws_per_segment2, screw_hole_diameter2,screw_head_diameter2, element_width2, false);
        }
    }
}

// shaft
translate([0, -tolerance, 0]) {
    rotate([90, 0, 0]) {
        color([1,1,1]) 
        cylinder(
            h = segment_count * segment_pitch - 2 * tolerance, 
            r = shaft_radius, 
            $fn = shaft_resolution
        );
    }
}
