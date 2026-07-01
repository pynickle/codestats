
CC = gcc
# Pure comment
CFLAGS = -Wall  # Mixed: code + comment

all: main.o
	$(CC) -o app main.o

main.o: main.c  # Another mixed line
	$(CC) $(CFLAGS) -c main.c

clean:
