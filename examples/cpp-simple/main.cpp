#include <string>
#include <algorithm>
#include <print>


const std::array greetings = {
	"Hello, world!",
	"Γειά σου, κόσμε!",
	"Hallo, Welt!",
};


int main() {
	std::for_each(greetings.begin(), greetings.end(), [](std::string value) {
		std::println("{}", value);
	});

	return 0;
}

