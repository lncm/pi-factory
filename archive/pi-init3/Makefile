all: clean boot/pi-init3

boot/pi-init3:
	GOOS=linux GOARCH=arm GOARM=5 go build -o boot/pi-init3 .

clean:
	rm -f boot/pi-init3

.PHONY: all clean
