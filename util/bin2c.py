import os

def main():
	for f in os.listdir('.'):
		exts = os.path.splitext(f)
		if os.path.isfile(f):
			if exts[1].lower() == '.lua':
				print f
				os.popen("lua ../util/bin2c.lua "+f+" > "+exts[0]+".luacb")

if __name__ == '__main__':
	main()