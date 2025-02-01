#include <raylib.h>
#include <raymath.h>


Vector2 DefaultWindowDimensions() {
	return Vector2Divide((Vector2) { GetMonitorPhysicalWidth(GetCurrentMonitor()), GetMonitorPhysicalHeight(GetCurrentMonitor()) }, (Vector2) { 2, 2 });
}

