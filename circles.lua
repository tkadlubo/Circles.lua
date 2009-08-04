#!/usr/bin/env lua

math.randomseed(os.time())

Decoder = { -- class {{{
    className = "Decoder"
}
-- Decoder end }}}


Encoder = { -- class {{{
    className = "Encoder"
}
function Encoder:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.geneticManager = GeneticManager:new()
    return o
end --}}}

function Encoder:encode(image) --{{{
    self.geneticManager:setTargetImage(image)
    local best = self.geneticManager:getBestFit()
    local bestFitness = self.geneticManager:fitness(best)
    print("Best fit: "..bestFitness)
    local generation = 0
    while true do
        generation = generation + 1
        print("Generation: "..generation)
        self.geneticManager:nextGeneration()
        local nextBest = self.geneticManager:getBestFit()
        local nextBestFitness = self.geneticManager:fitness(nextBest)
        nextBest:rasterize():writePPMFile("gen"..generation..".ppm")
        if nextBestFitness > bestFitness then
            bestFitness = nextBestFitness
            best = nextBest
            
            print("Best fit in generation "..generation..": "..bestFitness)
            best:rasterize():writePPMFile("best"..generation..".ppm")
        end
    end

end --}}}
-- Encoder end }}}


GeneticManager = { -- class {{{
    className = "GeneticManager",
    populationSize = 5,
    offspringCount = 5
}
function GeneticManager:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.population = {}
    return o
end --}}}

function GeneticManager:nextGeneration() --{{{
    -- One mutant, just for the kicks!
    for i = 1,self.offspringCount do
        local parent1 = self.population[math.random(#(self.population))]
        local parent2 = self.population[math.random(#(self.population))]

        local newImage = parent1..parent2

        table.insert(self.population, newImage)
    end

    self:sortPopulation()
    for i = self.populationSize+1, #self.population do
        self.population[i] = nil
    end
    
    collectgarbage("collect")
end --}}}

function GeneticManager:setTargetImage(image) --{{{
    self.targetImage = image
    for i = 1, self.populationSize do
        local newImage = VectorImage:new()
        newImage:setSize(image.width, image.height)
        newImage:randomize()
        table.insert(self.population, newImage)
    end
    self:sortPopulation()
end --}}}

function GeneticManager:fitness(image) --{{{
    local ppmImage
    if image.className == "PPMImage" then
        ppmImage = image
    else
        ppmImage = image:rasterize()
    end

    if ppmImage.fitness ~= nil then
        return ppmImage.fitness
    end

    sum = 0.0
    for x = 1,ppmImage.width,1 do
        for y = 1,ppmImage.height,1 do
            local delta = self.targetImage:pixelAt(x, y) - ppmImage:pixelAt(x, y)
            sum = sum + delta
        end
    end
    ppmImage.fitness = sum / (ppmImage.height * ppmImage.width)
    return ppmImage.fitness
end --}}}

function GeneticManager:sortPopulation() --{{{
    table.sort(
        self.population,
        function(a, b)
            return self:fitness(a) > self:fitness(b)
        end
    )
end --}}}

function GeneticManager:getBestFit() --{{{
    return self.population[1]
end --}}}
-- GeneticManager end }}}
GeneticManagerTest = { -- class {{{
    className = GeneticManagerTest
}
function GeneticManagerTest:setUp() --{{{
    self.testedGeneticManager = GeneticManager:new()
    self.testedGeneticManager:setTargetImage(PPMImage:new({}, "test.ppm"))
end --}}}

function GeneticManagerTest:testConstructor() --{{{
    assertEquals(type(self.testedGeneticManager), "table")
end --}}}

function GeneticManagerTest:testFitnessFunction() --{{{
    assertBetween(self.testedGeneticManager:fitness(self.testedGeneticManager.targetImage), 0.999, 1.001)
end --}}}

function GeneticManagerTest:testPopulation() --{{{
    assertEquals(type(self.testedGeneticManager.population), "table")
    assertEquals(#self.testedGeneticManager.population, self.testedGeneticManager.populationSize)
    for _,vectorImage in ipairs(self.testedGeneticManager.population) do
        assertType(vectorImage, "table")
        assertEquals(vectorImage.className, "VectorImage")
    end
end --}}}
-- GeneticManagerTest end }}}


Palette = { -- class {{{
    className = "Palette",
    colorCount = 10,
}
function Palette:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.colors = {}
    return o
end --}}}

function Palette:getRandomColor() --{{{
    return self.colors[math.random(self.colorCount)]
end --}}}

function Palette:randomizeColor() --{{{
    return {
        R = math.random(),
        G = math.random(),
        B = math.random()
    }
end --}}}

function Palette:randomize() --{{{
    for i=1,self.colorCount,1 do
        table.insert(self.colors, self:randomizeColor())
    end
end --}}}

function Palette.__concat(p1, p2) --{{{
-- concatenation metaoperation means genetic crossover
    local newPalette = Palette:new()

    local color
    for i = 1,newPalette.colorCount do
        local random = math.random(20)
        if random >= 19 then
            table.insert(newPalette.colors, newPalette:randomizeColor())
        else
            table.insert(newPalette.colors, {
                R = ((p1.colors[i].R * random) + (p2.colors[i].R * (19 - random))) / 19,
                G = ((p1.colors[i].G * random) + (p2.colors[i].G * (19 - random))) / 19,
                B = ((p1.colors[i].B * random) + (p2.colors[i].B * (19 - random))) / 19
            })
        end
    end

    return newPalette
end --}}}
-- Palette end }}}
PaletteTest = {} -- class {{{
function PaletteTest:setUp() -- {{{
    self.testedPalette = Palette:new()
end --}}}

function PaletteTest:testRandomize()
    self.testedPalette:randomize()
end
-- PaletteTest end }}}


PPMImage = { -- class {{{
    className = "PPMImage"
}
function PPMImage:new(o, image) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    if type(image) == "string" then
        o:readPPMFile(image)
    elseif type(image) == "table" then
        o:renderVectorImage(image)
    end
    return o
end --}}}

function PPMImage:renderVectorImage(image) --{{{
    self.depth = 255
    self.width, self.height = image.width, image.height
    self.data = {}
    for row = 1,self.height do
        local new_row = {}
        table.insert(self.data, new_row)
        for col = 1,self.width do
            table.insert(new_row, { R=0.0, G=0.0, B=0.0})
        end
    end
    
    for _,circle in ipairs(image.circles) do
        self:renderCircle(circle)
    end
end --}}}

function PPMImage:renderCircle(circle) --{{{
    local minX, maxX, minY, maxY
    local color = circle.color
    local rSquared = circle.radius * circle.radius
    minX = math.max(1, circle.x - circle.radius)
    maxX = math.min(self.width, circle.x + circle.radius)
    minY = math.max(1, circle.y - circle.radius)
    maxY = math.min(self.height, circle.y + circle.radius)
    for x = minX, maxX do
        for y = minY, maxY do
            if (x - circle.x)*(x - circle.x) + (y - circle.y)*(y - circle.y) <= rSquared then
                local pixel = self.data[y][x]
                pixel.R = (pixel.R + color.R) / 2
                pixel.G = (pixel.G + color.G) / 2
                pixel.B = (pixel.G + color.B) / 2
            end
        end
    end
end --}}}

function PPMImage:aspectRatio() --{{{
    return {self.width, self.height}
end --}}}

function PPMImage:pixelIterator() --{{{
    return coroutine.wrap(function() return self:pixelIteratorBody() end)
end --}}}

function PPMImage:pixelIteratorBody() --{{{
    for y = 1, self.height, 1 do
        for x = 1, self.width, 1 do 
            coroutine.yield(self:pixelAt(x, y))
        end
    end
end --}}}

PPMImage.pixelMetatable = { --{{{
    __sub = function(p1, p2)
        return 1.0 - (p1.R-p2.R) * (p1.R-p2.R)
                   - (p1.R-p2.G) * (p1.G-p2.G)
                   - (p1.B-p2.B) * (p1.B-p2.B)
    end,
    __tostring = function(p)
        return string.format("<R%d|G%d|B%d>", p.R, p.G, p.B)
    end
} --}}}

function PPMImage:pixelAt(x, y) --{{{
    return self.data[y][x]
end --}}}

function PPMImage:readPPMFile(fileName) --{{{
    local file = io.open(fileName, "r")
    assert(file ~= nil)

    self.parserState = "start"

    local parserStateMachine = { --{{{
        start = function(self, line) --{{{
            if line ~= "P3" then
                error("PPM syntax error in line "..self.line_counter..": only P3 format supported")
            end
            self.parserState = "aspectRatio"
        end, --}}}
        aspectRatio = function(self, line) --{{{
            local width, height = line:match("(%d+)%s+(%d+)")
            if width ~= nil and height ~=nil then
                self.width = tonumber(width)
                self.height = tonumber(height)
            else
                error("PPM syntax error in line "..self.line_counter..": invalid image size")
            end
            self.parserState = "colorDepth"
        end, --}}}
        colorDepth = function(self, line) --{{{
            self.depth = 255
            if line ~= "255" then
                error("PPM syntax error in line "..self.line_counter..": only 24bit images are supported")
            end
            self.parserState = "pixelData"
            self.x = 1
            self.y = 1
            self.data = {{}}
        end, --}}}
        pixelData = function(self, line) --{{{
            for pixel in line:gmatch("%d+%s+%d+%s+%d+%s*") do
                local R, G, B = pixel:match("(%d+)%s+(%d+)%s+(%d+)")
                if R == nil or G == nil or B == nil then
                    error("PPM syntax error in line "..self.line_counter..": invalid pixel data: "..line)
                end

                local pixel = {
                    R=tonumber(R)/self.depth,
                    G=tonumber(G)/self.depth,
                    B=tonumber(B)/self.depth
                }
                setmetatable(pixel, self.pixelMetatable)
                table.insert(self.data[self.y], pixel)

                self.x = self.x + 1
                if self.x > self.width then
                    self.x = 1
                    self.y = self.y + 1
                    table.insert(self.data, {})
                end
            
                if self.y == self.height + 1 then
                    self.parserState = "eof"
                end
            end
        end, --}}}
        eof = function(self, line) --{{{
            if line ~= nil then
                error("PPM syntax error in line "..self.line_counter..": EOF expected")
            end
        end --}}}
    } --}}}
    self.line_counter = 0
    for line in file:lines() do
        self.line_counter = self.line_counter + 1
        if line:sub(1, 1) ~= "#" then
            parserStateMachine[self.parserState](self, line)
        end
    end
    if self.parserState ~= "eof" then
         error("PPM syntax error at end of file")
    end

    file:close()
end --}}}

function PPMImage:writePPMFile(fileName) --{{{
    assert(type(fileName) == "string")

    local file = io.open(fileName, "w")
    
    file:write("P3\n")
    file:write(tostring(self.width).." "..tostring(self.height).."\n")
    file:write("255\n")
    for pixel in self:pixelIterator() do
        file:write(string.format("%d %d %d\n",
            pixel.R * self.depth,
            pixel.G * self.depth,
            pixel.B * self.depth
        ))
    end

    file:close()
end --}}}
-- PPMImage end }}}
PPMImageTest = {} -- class {{{
function PPMImageTest:setUp()
    self.testedImage = PPMImage:new({}, "test.ppm")
end

function PPMImageTest:testAspectRatio() --{{{
    local aspectRatio = self.testedImage:aspectRatio()
    assertEquals(aspectRatio[1], 3)
    assertEquals(aspectRatio[2], 2)
end --}}}

function PPMImageTest:testConstructor() --{{{
    assertEquals(type(self.testedImage), "table")
end --}}}

function PPMImageTest:testFileData() --{{{
    local pixel22 = self.testedImage:pixelAt(2, 2)
    assertEquals(type(pixel22), "table")
    assertEquals(pixel22.R, 1)
    assertEquals(pixel22.G, 1)
    assertEquals(pixel22.B, 1)
end --}}}

function PPMImageTest:testWrite() --{{{
    local tmpFile = os.tmpname()
    self.testedImage:writePPMFile(tmpFile)
end --}}}
-- PPMImageTest end }}}


VectorImage = { -- class {{{
    className = "VectorImage",
    circlesCount = 25,
}
function VectorImage:new(o, data) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.circles = {}
    return o
end --}}}

function VectorImage:createRandomCircle() --{{{
    return {
        x = math.random(self.width),
        y = math.random(self.height),
        radius = math.random(self.maxRadius),
        color = self.palette:getRandomColor()
    }
end --}}}

function VectorImage:setSize(width, height)
    self.width = width
    self.height = height
    self.maxRadius = math.floor(math.min(width, height)/2)
end

function VectorImage:randomize() --{{{
    self.palette = Palette:new()
    self.palette:randomize()
    for i = 1,self.circlesCount,1 do
        table.insert(self.circles, self:createRandomCircle())
    end
end --}}}

function VectorImage:rasterize() --{{{
    if self.rasterizedImage ~= nil then
        return self.rasterizedImage
    end

    self.rasterizedImage = PPMImage:new({}, self)
    return self.rasterizedImage
end --}}}

function VectorImage:writeTwit(outputFile) --{{{
    local ppmImage = self:rasterize()
    ppmImage:writePPMFile(outputFile)
end --}}}

function VectorImage.__concat(v1, v2)
    local newVectorImage = VectorImage:new()
    newVectorImage:setSize(v1.width, v2.height)
    newVectorImage.palette = v1.palette..v2.palette

    local circle
    for i = 1,newVectorImage.circlesCount do
        local random = math.random(20)
        if random >= 19 then
            table.insert(newVectorImage.circles, newVectorImage:createRandomCircle())
        else
            local circle1 = v1.circles[i]
            local circle2 = v2.circles[i]
            table.insert(newVectorImage.circles, {
                x = ((circle1.x * random) + (circle2.x * (19 - random))) / 19,
                y = ((circle1.y * random) + (circle2.y * (19 - random))) / 19,
                radius = ((circle1.radius * random) + (circle2.radius * (19 - random))) / 19,
                color = newVectorImage.palette:getRandomColor()
            })
        end
    end

    return newPalette
end
-- VectorImage end }}}
VectorImageTest = {} -- class {{{
function VectorImageTest:setUp() --{{{
    self.testedImage = VectorImage:new()
end --}}}

function VectorImageTest:testConstructor() --{{{
    assertEquals(type(self.testedImage), "table")
end --}}}

function VectorImageTest:testRandomizeCreatesCircles() --{{{
    self.testedImage:setSize(3, 4)
    self.testedImage:randomize()
    assertType(self.testedImage.circles, "table")
    assertEquals(self.testedImage.circlesCount, #(self.testedImage.circles))
end --}}}

function VectorImageTest:testCirclesHaveDimensions() --{{{
    self.testedImage:setSize(3, 4)
    self.testedImage:randomize()
    assertType(self.testedImage.circlesCount, "number")
    assertGreaterThan(0, self.testedImage.circlesCount)
    for i = 1,self.testedImage.circlesCount, 1 do
        assertType(self.testedImage.circles[i], "table")
        assertBetween(self.testedImage.circles[i].radius, 0, self.testedImage.maxRadius)
        assertBetween(self.testedImage.circles[i].x, 0, self.testedImage.width)
        assertBetween(self.testedImage.circles[i].y, 0, self.testedImage.height)
    end
end --}}}

function VectorImageTest:testRasterize() --{{{
    self.testedImage:setSize(3, 4)
    self.testedImage:randomize()
    local ppmImage = self.testedImage:rasterize()
    assertEquals(ppmImage.width, 3)
    assertEquals(ppmImage.height, 4)
    assertType(ppmImage.data, "table")
    assertEquals(#(ppmImage.data), 4)
    assertEquals(#(ppmImage.data[1]), 3)
end --}}}
-- VectorImageTest end }}}


function main(operation, inputFile, outputFile) --{{{
    if operation == "encode" then
        if inputFile == nil or outputFile == nil then
            error("Invalid command line parameters")
        end
        encoder = Encoder:new()
        inputImage = PPMImage:new({}, inputFile)
        outputImage = encoder:encode(inputImage)
        outputImage:writeTwit(outputFile)
        return
    elseif operation == "decode" then
        if inputFile == nil or outputFile == nil then
            error("Invalid command line parameters")
        end
        decoder = Decoder:new()
        inputImage = decoder.readTwit(inputFile)
        outputImage = PPMImage:new(inputImage)
        outputImage.write(outputFile)
        return
    elseif operation == "test" then
        require("luaunit")
        LuaUnit:run("GeneticManagerTest", "PaletteTest", "PPMImageTest", "VectorImageTest")
    else
        error("Unknown operation")
    end
end --}}}

main(...)

-- vim: ts=4:expandtab:foldmethod=marker
