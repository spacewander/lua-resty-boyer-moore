LIB := librestyboyermoore.so
SRC := $(wildcard *.c)
OBJ := $(SRC:.c=.o)
CFLAGS := -O3 -g -Wall -Wextra -Werror -fpic
LDFLAGS := -shared

all : $(LIB)

${OBJ} : %.o : %.c
	$(CC) $(CFLAGS) $(CEXTRAFLAGS) -c $<

${LIB} : ${OBJ}
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f $(LIB) *.o

test: $(LIB)
	prove -r t/

full-test: $(LIB)
	TEST_NGINX_VALGRIND=1 prove -r t/
