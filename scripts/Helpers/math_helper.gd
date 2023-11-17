# Math Helper Class
# Should be Autoloaded (Project Settings -> Autoload)
class_name MathHelper extends Node2D

# Returns the center of all points in the array
func get_centroid(points:Array) -> Vector2:
	var centroid = [0,0];

	for i in points.size():
		centroid[0] += points[i].x
		centroid[1] += points[i].y
		
	var totalPoints = points.size();
	centroid[0] = centroid[0] / totalPoints;
	centroid[1] = centroid[1] / totalPoints;

	return Vector2(centroid[0],centroid[1]);
