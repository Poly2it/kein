#include <stdio.h>
#include "../primitives.h"


const c8* greetings[] = {
	"Hello, world!",
	"Γειά σου, κόσμε!",
	"Hallo, Welt!",
};


int main() {
	for (u32 h = 0; h < 3; h += 1) {
		printf("%s\n", greetings[h]);
	}
	return 0;
}

