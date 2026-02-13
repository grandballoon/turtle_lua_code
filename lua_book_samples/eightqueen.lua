N = 8

-- check whether position (n,c) is free from attacks from previously placed queens.
-- more specifically, it checks whether putting the n-th queen in column c will
-- conflict with any of the previous n-1 queens already set in the array a.
-- by representation, no two queens can be in the same row, so this function
-- checks columns and diagonals.
function isplaceok (a, n, c)
    for i = 1, n - 1 do
        if (a[i] == c) or 
           (a[i] - i == c) or
           (a[i] + i == c + n) then
            return false
        end
    end
    return true
end

-- print a board
function printsolution (a)
    for i = 1, N do         -- for each row
        for j = 1, N do     -- and for each column
                            -- write "X" or "-" plus a space
            io.write(a[i] == j and "X" or "-", " ")
        end
        io.write("\n")
    end
    io.write("\n")
end

-- add to board 'a' all queens from 'n' to 'N'. This is the core of the program.
-- It tries to place all queens larger than or equal to n in the board. 
-- It uses backtracking to search for valid solutions. First, it checks whether
-- the solution is complete, and, if so, prints that solution. Otherwise, it loops
-- through all columns for the n-th queen; for each column that is free from attacks,
-- the program places the queen there and recursively tries to place the following
-- queens.
function addqueen (a, n)        
    if n > N then               -- all queens have been placed?
        printsolution(a)
    else                        -- try to place n-th queen
        for c = 1, N do
            if isplaceok(a, n, c) then
                a[n] = c        -- place n-th queen at column 'c' 
                addqueen(a, n + 1)
            end
        end
    end
end

-- call addqueen on an empty solution.
addqueen({}, 1)