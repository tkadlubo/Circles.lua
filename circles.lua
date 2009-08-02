#!/usr/bin/env lua

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

    return self.geneticManager:getBestFit()
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
    for i = 1, o.populationSize, 1 do
        newImage = VectorImage:new()
        table.insert(o.population, newImage)
        newImage:randomize()
    end
    return o
end --}}}

function GeneticManager:next_generation() --{{{
end --}}}

function GeneticManager:setTargetImage(image) --{{{
    self.targetImage = image
end --}}}

function GeneticManager:fitness(vectorImage) --{{{
    local ppmImage = vectorImage:rasterize()
    sum = 0.0
    for x = 1,ppmImage.width,1 do
        for y = 1,ppmImage.height,1 do
            local delta = self.targetImage:pixelAt(x, y) - ppmImage:pixelAt(x, y)
            sum = sum + delta
        end
    end
    return sum / (ppmImage.height * ppmImage.width)
end --}}}

function GeneticManager:sortPopulation() --{{{
    table.sort(
        self.population,
        function(a, b)
            local aFitness, bFitness = self:fitness(a), self:fitness(b)
        end
    )
end --}}}

function GeneticManager:getBestFit() --{{{
    self:sortPopulation()
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
    assertEquals(type(self.testedGeneticManager.population), "table")
    assertEquals(#self.testedGeneticManager.population, self.testedGeneticManager.populationSize)
end --}}}

function GeneticManagerTest:testFitnessFunction() --{{{
    assertBetween(self.testedGeneticManager:fitness(self.testedGeneticManager.targetImage), 0.999, 1.001)
end --}}}
-- GeneticManagerTest end }}}


Palette = { -- class {{{
    className = "Palette",
    colorCount = 10,
}
function Palette:new(o, data) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.colors = {}
    return o
end --}}}

function Palette:pickRandomColor()
    return self.colors[math.random(self.colorCount)]
end

function Palette:randomize() --{{{
    for i=1,self.colorCount,1 do
        table.insert(self.colors, {
            r = math.random(),
            g = math.random(),
            b = math.random()
        })
    end
end
--}}}
-- Palette end }}}
PaletteTest = {} -- class {{{
function PaletteTest:setUp() -- {{{
    self.testedPalette = Palette:new()
end --}}}

function PaletteTest:testRandomize()
    self.testedPalette:randomize()
end
-- PaletteTest end }}}


PPMImage = {} -- class {{{
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
    self.width, self.height = image.width, image.height
    self.data = {}
    for row = 1,self.height do
        local new_row = {}
        table.insert(self.data, new_row)
        for col = 1,self.width do
            table.insert(new_row, { R=0.0, G=0.0, B=0.0})
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
    circlesCount = 10,
    maxX = 100,
    maxY = 100,
    maxRadius = 50
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
        x = math.random(self.maxX),
        y = math.random(self.maxY),
        radius = math.random(self.maxRadius)
    }
end --}}}

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

    self.rasterizedImage = PPMImage:new(self)
    return self.rasterizedImage
end --}}}

-- VectorImage end }}}
VectorImageTest = {} -- class {{{
function VectorImageTest:setUp() --{{{
    self.testedImage = VectorImage:new()
end --}}}

function VectorImageTest:testConstructor() --{{{
    assertEquals(type(self.testedImage), "table")
end --}}}

function VectorImageTest:testRandomizeCreatesCircles() --{{{
    self.testedImage:randomize()
    assertType(self.testedImage.circles, "table")
    assertEquals(self.testedImage.circlesCount, #(self.testedImage.circles))
end --}}}

function VectorImageTest:testCirclesHaveDimensions() --{{{
    self.testedImage:randomize()
    assertType(self.testedImage.circlesCount, "number")
    assertGreaterThan(0, self.testedImage.circlesCount)
    for i = 1,self.testedImage.circlesCount, 1 do
        assertType(self.testedImage.circles[i], "table")
        assertBetween(self.testedImage.circles[i].radius, 0, self.testedImage.maxRadius)
        assertBetween(self.testedImage.circles[i].x, 0, self.testedImage.maxX)
        assertBetween(self.testedImage.circles[i].y, 0, self.testedImage.maxY)
    end
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
        outputImage.writeTwit(outputFile)
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
