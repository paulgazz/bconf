CPROGS := bconf
GENERATED := bconf.tab.c bconf.lex.c

.PHONY: all clean clobber

all: $(GENERATED) $(CPROGS)

bconf.tab.c: bconf.lex.c

bconf: bconf.tab.c
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.tab.c: %.y
	bison -l -b $* -p $* -t $<

%.lex.c: %.l
	flex -o $@ $<

clean:
	$(RM) $(CPROGS) *.o

clobber:
	$(RM) $(GENERATED)
