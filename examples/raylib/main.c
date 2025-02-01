#include <raylib.h>
#include "utils.h"



int main() {
	SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_WINDOW_TOPMOST);
	InitWindow(800, 400, "Raylib");

	Vector2 windowDimensions = DefaultWindowDimensions();
	SetWindowSize(windowDimensions.x, windowDimensions.y);

	SetTargetFPS(60);
	while (!WindowShouldClose())
	{
		BeginDrawing();
		ClearBackground(RAYWHITE);
		DrawText(TextFormat("FPS: %d", GetFPS()), 10, 10, 20, BLUE);
		EndDrawing();
	}

	CloseWindow();

	return 0;
}

