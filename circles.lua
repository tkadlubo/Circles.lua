#!/usr/bin/env lua

-- circles.lua, an experimental image encoder/decoder
-- Copyright (C) 2009 Tadeusz Andrzej Kadlubowski yess@hell.org.pl
--
--This program is free software; you can redistribute it and/or
--modify it under the terms of the GNU General Public License
--as published by the Free Software Foundation; either version 2
--of the License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program; if not, write to the Free Software
--Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

math.randomseed(os.time())

mutation_param = 17

Decoder = { -- class {{{
    className = "Decoder"
}
-- Decoder end }}}


Deserializer = { -- class {{{
}

function Deserializer:initSourceFile(fileName) --{{{
end --}}}

function Deserializer:deserializeNumber(bitWidth) --{{{
end --}}}

-- Deserializer end }}}
 
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
    for i=1,2 do
        generation = generation + 1
        self.geneticManager:nextGeneration()
        local nextBest = self.geneticManager:getBestFit()
        local nextBestFitness = self.geneticManager:fitness(nextBest)
        print("Generation: "..generation.."\t Avg. fitness: "..self.geneticManager:averageFitness().."\t Best fitness: "..nextBestFitness)
        nextBest:rasterize():writePPMFile("gen"..generation..".ppm")

        if nextBestFitness > bestFitness then
            bestFitness = nextBestFitness
            best = nextBest
            
            print("Best fit in generation "..generation..": "..bestFitness)
            best:rasterize():writePPMFile("best"..generation..".ppm")
            
            local diffImage = best:rasterize() - self.geneticManager.targetImage
            diffImage:writePPMFile("diff"..generation..".ppm")
        end

        return best        
    end

end --}}}
-- Encoder end }}}


GeneticManager = { -- class {{{
    className = "GeneticManager",
    populationSize = 35,
    offspringCount = 15
}
function GeneticManager:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.population = {}
    return o
end --}}}

function GeneticManager:nextGeneration() --{{{
    for i = 1,#self.population do
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
    self.defaultBackgroundColor = image:getAverageColor()
    for i = 1, self.populationSize do
        local newImage = VectorImage:new({}, self.defaultBackgroundColor)
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

function GeneticManager:averageFitness()
    sum = 0.0
    for i,image in ipairs(self.population) do
        sum = sum + self:fitness(image)
    end

    return sum/#self.population
end

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

function GeneticManagerTest:testNextGeneration() --{{{
    local oldPopulation = self.testedGeneticManager.population
    self.testedGeneticManager:nextGeneration()
    for i,image in ipairs(self.testedGeneticManager.population) do
        assertType(image, "table")
        assertEquals(image.className, "VectorImage")
    end
end --}}}
-- GeneticManagerTest end }}}


Palette = { -- class {{{
    className = "Palette",
    colorCount = 7,
}
function Palette:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.colors = {}
    return o
end --}}}

function Palette:getRandomColor() --{{{
    return math.random(self.colorCount)
end --}}}

function Palette:getColor(index) --{{{
    return self.colors[index]
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
        local randomR = math.random(20)
        local randomG = math.random(20)
        local randomB = math.random(20)

        local newColor = {}
        if randomR >= mutation_param then
            newColor.R = math.random()
        else
            newColor.R = ((p1.colors[i].R * randomR) + (p2.colors[i].R * (mutation_param - randomR))) / mutation_param
        end
        if randomG >= mutation_param then
            newColor.G = math.random()
        else
            newColor.G = ((p1.colors[i].G * randomG) + (p2.colors[i].G * (mutation_param - randomG))) / mutation_param
        end
        if randomB >= mutation_param then
            newColor.B = math.random()
        else
            newColor.B = ((p1.colors[i].B * randomB) + (p2.colors[i].B * (mutation_param - randomB))) / mutation_param
        end

        table.insert(newPalette.colors, newColor)
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
    local backgroundColor = image.defaultBackgroundColor
    local R = backgroundColor.R
    local G = backgroundColor.G
    local B = backgroundColor.B
    self.depth = 255
    self.width, self.height = image.width, image.height
    self.data = {}
    for row = 1,self.height do
        local new_row = {}
        table.insert(self.data, new_row)
        for col = 1,self.width do
            table.insert(new_row, { R=R, G=G, B=B})
        end
    end
    
    for _,circle in ipairs(image.circles) do
        self:renderCircle(circle, image.palette:getColor(circle.color))
    end
end --}}}

function PPMImage:renderCircle(circle, color) --{{{
    local minX, maxX, minY, maxY
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

function PPMImage:getAverageColor() --{{{
    local R = 0
    local G = 0
    local B = 0
    for x = 1,self.width do
        for y = 1,self.height do 
            R = R + self.data[y][x].R
            G = G + self.data[y][x].G
            B = B + self.data[y][x].B
        end
    end
    return {
        R = R / (self.width * self.height),
        G = G / (self.width * self.height),
        B = B / (self.width * self.height)
    }
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
        return 1.0 - ((p1.R-p2.R) ^ 2)
                   - ((p1.R-p2.G) ^ 2)
                   - ((p1.B-p2.B) ^ 2)
    end,
    __tostring = function(p)
        return string.format("<R%d|G%d|B%d>", p.R, p.G, p.B)
    end
} --}}}

function PPMImage:pixelAt(x, y) --{{{
    return self.data[y][x]
end --}}}

function PPMImage:setSize(width, height) --{{{
    self.width = width
    self.height = height
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
                self:setSize(tonumber(width), tonumber(height))
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

function PPMImage.__sub(image1, image2) --{{{
    local newPPMImage = PPMImage:new()
    
    newPPMImage:setSize(image1.width, image1.height)

    newPPMImage.depth = image1.depth
    newPPMImage.data = {}
    for y = 1,newPPMImage.height do
        table.insert(newPPMImage.data, {})
        for x = 1,newPPMImage.width do
            local p1 = image1:pixelAt(x,y)
            local p2 = image2:pixelAt(x,y)
            local newPixel = {
                R = 0.5 + (p1.R - p2.R) / 2,
                G = 0.5 + (p1.G - p2.G) / 2,
                B = 0.5 + (p1.B - p2.B) / 2
            }
            table.insert(newPPMImage.data[y], newPixel)
        end
    end

    return newPPMImage
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


Serializer = { --class --{{{
}
function Serializer:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end --}}}

function Serializer:serializeSize(width, height) --{{{
end --}}}

function Serializer:serializePalette(palette) --{{{
end --}}}

function Serializer:serializeCircle(circle) --{{{
end --}}}

function Serializer:serializeNumber(x, bitWidth) --{{{
end --}}}
-- Serializer end }}}


VectorImage = { -- class {{{
    className = "VectorImage",
    circlesCount = 45,
}
function VectorImage:new(o, defaultBackgroundColor) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.defaultBackgroundColor = defaultBackgroundColor
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

function VectorImage:setSize(width, height) --{{{
    self.width = width
    self.height = height
    self.maxRadius = math.floor(math.min(width, height)/2)
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

    self.rasterizedImage = PPMImage:new({}, self)
    return self.rasterizedImage
end --}}}

function VectorImage:writeTwit(outputFile) --{{{
    local bitField = serialize
end --}}}

function VectorImage.__concat(v1, v2)
    local newVectorImage = VectorImage:new({}, v1.defaultBackgroundColor)
    newVectorImage:setSize(v1.width, v1.height)
    newVectorImage.palette = v1.palette..v2.palette

    for i = 1,newVectorImage.circlesCount do
        local randomX = math.random(20)
        local randomY = math.random(20)
        local randomRadius = math.random(20)
        local circle1 = v1.circles[i]
        local circle2 = v2.circles[i]
        local newCircle = {color = circle1.color}

        if randomX >= mutation_param then
            newCircle.x = math.random(v1.width)
        else
            newCircle.x = math.floor(((circle1.x * randomX) + (circle2.x * (mutation_param - randomX))) / mutation_param) + 1
        end
        if randomY >= mutation_param then
            newCircle.y = math.random(v2.height)
        else
            newCircle.y = math.floor(((circle1.y * randomY) + (circle2.y * (mutation_param - randomY))) / mutation_param)  + 1
        end
        if randomRadius >= mutation_param then
            newCircle.radius = math.random(v1.maxRadius)
        else
            newCircle.radius = math.floor(((circle1.radius * randomRadius) + (circle2.radius * (mutation_param - randomRadius))) / mutation_param) + 1
        end
        table.insert(newVectorImage.circles, newCircle)
    end

    return newVectorImage
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
    self.testedImage.defaultBackgroundColor = {R=0.0, G=0.0, B=0.0}
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
        local encoder = Encoder:new()
        local inputImage = PPMImage:new({}, inputFile)
        local outputImage = encoder:encode(inputImage)
        outputImage:writeTwit(outputFile)
        return
    elseif operation == "decode" then
        if inputFile == nil or outputFile == nil then
            error("Invalid command line parameters")
        end
        local decoder = Decoder:new()
        local inputImage = decoder.readTwit(inputFile)
        local outputImage = PPMImage:new(inputImage)
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
