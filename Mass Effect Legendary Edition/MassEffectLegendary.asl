state("MassEffect1", "ME1 2.0.0.48602")
{
	bool isLoading : 0x1780D1C; // up to 7 while loading
	//bool isLoading2 : 0x1770664;  // experimental, don't use as it's broken
}

state("MassEffect2", "ME2 2.0.0.48602")
{
	bool isLoading : 0x175E9C4; // up to 7 while loading
}

state("MassEffect3", "ME3 2.0.0.48602")
{
	bool isLoading : 0x179AF10; // up to 7 while loading
}

init
{
	if (modules.First().ModuleMemorySize == 0x1DB8000) {
		version = "ME1 2.0.0.48602";
	} else if (modules.First().ModuleMemorySize == 0x1D6A000) {
		version = "ME2 2.0.0.48602";
	} else if (modules.First().ModuleMemorySize == 0x1ED2000) {
		version = "ME3 2.0.0.48602";
	}
}

isLoading
{
    return (current.isLoading);
}