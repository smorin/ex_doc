CFLAGS=-g -O3 -fPIC
LDFLAGS=-Isundown/src -Isundown/html
ERLANG_FLAGS=-I`erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell`
CC=gcc
EBIN_DIR=ebin

SUNDOWN_SRC=\
	    sundown/src/buffer.o\
	    sundown/src/markdown.o\
	    sundown/src/stack.o\
	    sundown/src/autolink.o\
	    sundown/html/html.o\
	    sundown/html/html_smartypants.o\
	    sundown/html/houdini_html_e.o\
	    sundown/html/houdini_href_e.o

NIF_SRC=\
	src/markdown_nif.o

.PHONY: setup test clean

compile: ebin

setup: markdown.so

ebin: $(shell find . -type f -name "*.ex")
	@ rm -f ebin/::*.beam
	@ echo Compiling ...
	@ mkdir -p $(EBIN_DIR)
	@ touch $(EBIN_DIR)
	elixirc lib/*/*/*.ex lib/*/*.ex lib/*.ex -o ebin
	@ echo

compile_test:
	@ rm -rf test/tmp/*
	@ elixirc --docs test/fixtures/*.ex -o test/tmp

test: markdown.so compile compile_test
	@ echo Running tests ...
	time elixir -pa test/tmp -pa ebin -r "test/**/*_test.exs"
	@ echo

clean:
	rm -f sundown/src/*.o sundown/html/*.o src/*.o
	rm share/markdown.so
	rm -rf $(EBIN_DIR)
	@ echo

markdown.so: $(SUNDOWN_SRC) $(NIF_SRC)
	$(CC) $(CFLAGS) -dynamiclib -undefined dynamic_lookup -o share/$@ $(SUNDOWN_SRC) $(NIF_SRC)

%.o: %.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(ERLANG_FLAGS) -c -o $@ $^
