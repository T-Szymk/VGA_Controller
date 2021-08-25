import os

commands = ["make sim_vga_controller"]

def main():
    
	output = []
	i = 0

	for command in commands:
		stream = os.popen(command)
		output.append(stream.readlines())
		for line in output[i]:
			if "Errors:" in line:
				print(f"\033[92;1;4m{line}", end="")
		i += 1
	print(f"\033[0mComplete!")

if __name__=='__main__':
	main()