#! /usr/bin/ruby

class Interpreter
    # Class constructor. It does how constructors do
    def initialize(file)
        #@commands = ['+', '-', '*', '/', '%', '!', '`', '>', '<', '^', 'v', '?', '_', '|', '"', ':', '\\', '$', '.', ',', '#', 'g', 'p', '&', '~', '@']
        @stop = false

        @file = file
        @source_lines = Array.new()
        @stack = Array.new()
        @line_num = 0
        @col_num = 0
        @curr_char = ''
        @curr_direction = :right
        @skip = false
        @ascii_mode = false
        checkfile()
    end

    # Checks that the filename provided exists and that it is indeed a file
    # and not a directory
    def checkfile()
        if not File.file?(@file)
            abort("File #{@file} does not exist. Aborting...")
        end
    end

    # Start interpreting the file
    def start()
        source_in = File.new(@file, "r")
        read_source(source_in)
        execute()
    end

    # Read in all of the source file so we can navigate around it
    def read_source(source_file)
        @source_lines = source_file.readlines()
    end

    # Sets the interpreter into stepping mode for debugging
    def debug()
        # =========================================
        # DEBUG CODE FOR STEPPING
        # =========================================
        debugging = false
        if not debugging
            return
        end

        puts "Curr char is: #{@curr_char}"
        puts "PC direction is: #{@curr_direction}"
        puts "Stack contents are: #{@stack}"
        puts "Skip is: #{@skip}"
        puts "Ascii_Mode is: #{@ascii_mode}"
        prompt()
        STDIN.gets

        # =========================================
        # END DEBUG CODE
        # =========================================

    end

    def popstack()
        if @stack.length == 0
            return 0
        else
            return @stack.pop()
        end
    end

    # Execute the statements in the source file
    def execute()
        while !@stop  do
            # This is so that the next instruction or bit of data is skipped.
            # The current character is updated twice in the true case purely for debugging purposes
            if @skip == true
                @curr_char = @source_lines[@line_num][@col_num]
                debug()

                @skip = false
                move()
                @curr_char = @source_lines[@line_num][@col_num]
                debug()
            else
                @curr_char = @source_lines[@line_num][@col_num]
                debug()
            end


            if @ascii_mode == true
                if @curr_char == '"'
                    @ascii_mode = false
                else
                    @stack.push(@curr_char.ord())
                end

                move()
                next
            end


            case @curr_char
            when '+'
                # Pop two values a and b then push the result a+b
                a = popstack()
                b = popstack()
                @stack.push(a + b)
            when '-'
                # Pop two values a and b then push the result b-a
                a = popstack()
                b = popstack()
                @stack.push(b - a)
            when '*'
                # Pop two values a and b then push the result a*b
                a = popstack()
                b = popstack()
                @stack.push(a * b)
            when '/'
                # Pop two values a and b then push the result b/a.
                # If a is zero ask the user what result they want (this is actually in the spec)
                a = popstack()
                b = popstack()

                if a == 0
                    puts "Division by zero! What result do you want this to have?"
                    loop do
                        prompt()
                        ans = STDIN.gets

                        if ans.respond_to?("to_i")
                            @stack.push(ans.to_i())
                            break
                        elsif ans.respond_to?("ord")
                            @stack.push(ans.ord())
                            break
                        end
                        puts "Invalid answer, please enter a better one"
                    end
                else
                    @stack.push(b/a.floor())
                end
            when '%'
                # Pop two values a and b then push the result b%a.
                # If a is zero ask the user what result they want. Not in the spec but seems appropriate.
                a = popstack()
                b = popstack()

                if a == 0
                    puts "Division by zero! What result do you want this to have?"
                    loop do
                        prompt()
                        ans = STDIN.gets

                        if ans.respond_to?("to_i")
                            @stack.push(ans.to_i())
                            break
                        elsif ans.respond_to?("ord")
                            @stack.push(ans.ord())
                            break
                        end
                        puts "Invalid answer, please enter a better one"
                    end
                else
                    @stack.push(b%a)
                end
            when '!'
                # Pop a value a and perform logical NOT on it. If it is 0, push 1 otherwise push 0.
                a = popstack()
                if a == 0
                    @stack.push(1)
                else
                    @stack.push(0)
                end
            when '`'
                # Greater than. Pop two values a and b and push 1 if b>a otherwise 0.
                a = popstack()
                b = popstack()

                if b > a
                    @stack.push(1)
                else
                    @stack.push(0)
                end
            when '>'
                # PC direction right
                @curr_direction = :right
            when '<'
                # PC direction left
                @curr_direction = :left
            when '^'
                # PC direction up
                @curr_direction = :up
            when 'v'
                # PC direction down
                @curr_direction = :down
            when '?'
                # Random PC direction
                prng = Random.new()
                num = prng.rand(4)

                case num
                when 0
                    @curr_direction = :up
                when 1
                    @curr_direction = :down
                when 2
                    @curr_direction = :left
                when 3
                    @curr_direction = :right
                end
            when '_'
                # Horizontal if. Pop a value. PC goes right if it is zero, left otherwise
                a = popstack()

                if a == 0
                    @curr_direction = :right
                else
                    @curr_direction = :left
                end
            when '|'
                # Vertical if. Pop a value. PC goes down if it is zero, up otherwise
                a = popstack()

                if a == 0
                    @curr_direction = :down
                else
                    @curr_direction = :up
                end
            when '"'
                # Toggle stringmode. Push each character's ASCII value until we see the next '"'
                @ascii_mode = !@ascii_mode
            when ':'
                # Duplicate top stack value
                a = popstack()
                @stack.push(a)
                @stack.push(a)
            when '\\'
                # Swap top stack values
                a = popstack()
                b = popstack()
                @stack.push(a)
                @stack.push(b)
            when '$'
                # Discard top stack value
                popstack()
            when '.'
                # Pop the top of the stack and output as integer
                a = popstack()

                if a.respond_to?("ord")
                    print a.ord
                else
                    print a
                end
            when ','
                # Pop the top of the stack and output as ASCII character
                a = popstack()

                if a.respond_to?("chr")
                    print a.chr
                else
                    print a
                end
            when '#'
                # Jump over the next command in the current direction of the current PC
                @skip = true
            when 'g'
                # A get call. Basically the program and data are stored together so this pops two values y and x
                # and retrieves the character at (x,y). It then pushes the ASCII value of this character
                # If (x,y) is out of bounds, push 0 as per the specification.
                y = popstack()
                x = popstack()

                if @source_lines.length <= y
                    @stack.push(0)
                elsif @source_lines[y].length <= x
                    @stack.push(0)
                else
                    c = @source_lines[y][x]

                    if c.respond_to?("ord")
                        @stack.push(c.ord())
                    end
                end
            when 'p'
                # A put call. Retrieves co-ordinates y and x from the stack and also a value v. It then changes
                # the character at (x,y) to the character with ASCII value v
                y = popstack()
                x = popstack()
                v = popstack()

                if v.respond_to?("chr")
                    @source_lines[y][x] = v.chr()
                end
            when '&'
                # Get integer from user and push it
                puts "Enter an integer"
                loop do
                    prompt()
                    ans = STDIN.gets

                    if ans.respond_to?("to_i")
                        @stack.push(ans.to_i())
                        break
                    end
                    puts "Not an integer. Please enter only digits"
                end
            when '~'
                # Get a character from user and push it
                puts "Enter a character"
                loop do
                    prompt()
                    ans = STDIN.gets

                    if ans.respond_to?("ord")
                        @stack.push(ans.ord())
                        break
                    end
                    puts "Please enter a character"
                end
            when '@'
                # End program
                puts "\n\nProgram finished. Exiting..."
                @stop = true
            when '0'..'9'
                # Push integer onto stack
                @stack.push(@curr_char.to_i())
            end

            # Move the PC
            move()
        end
    end

    def prompt()
        print("> ")
    end

    def move()
        case @curr_direction
        when :up
            @line_num -= 1
        when :down
            @line_num += 1
        when :left
            @col_num -= 1
        when :right
            @col_num += 1
        end
    end
end


if __FILE__ == $0
    if ARGV.length < 1
        puts "Pls, supply a file as an argument"
        puts "Usage ./thefudge <source_file>"
        exit(1)
    end

    interp = Interpreter.new(ARGV[0])
    puts "Starting interpreter...\n\n"
    interp.start()
end

