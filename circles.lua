#!/usr/bin/env lua


Decoder = {} -- class {{{
-- Decoder end }}}


Encoder = {} -- class {{{
function Encoder:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.geneticManager = GeneticManager:new()
    return o
end --}}}

function Encoder:encode(image)
    self.geneticManager:setTargetImage(image)
end
-- Encoder end }}}


GeneticManager = {} -- class {{{
function GeneticManager:new(o) --{{{
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end --}}}

function GeneticManager:setTargetImage(image) --{{{
    self.targetImage = image
end --}}}

function GeneticManager:fitness(vectorImage) --{{{
    return 0
end --}}}
-- GeneticManager end }}}
GeneticManagerTest = {} -- class {{{
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
-- GeneticManagerTest end }}}


Palette = {} -- class {{{
-- Palette end }}}


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

function PPMImage:aspectRatio() --{{{
    return {self.width, self.height}
end --}}}

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

                table.insert(self.data[self.y], {R=tonumber(R), G=tonumber(G), B=tonumber(B)})

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
    local aspectRatio = self:aspectRatio()
    local width, height = aspectRatio[1], aspectRatio[2]
    file:write(tostring(width).." "..tostring(height).."\n")
    file:write("255\n")
    for y = 1, height, 1 do
        for x = 1, width, 1 do 
            local pixel = self:pixelAt(x, y)
            file:write(tostring(pixel.R).." "..tostring(pixel.G).." "..tostring(pixel.B).."\n")
        end
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
    assertEquals(pixel22.R, 255)
    assertEquals(pixel22.G, 255)
    assertEquals(pixel22.B, 255)
end --}}}

function PPMImageTest:testWrite() --{{{
    local tmpFile = os.tmpname()
    self.testedImage:writePPMFile(tmpFile)
end --}}}
-- PPMImageTest end }}}


VectorImage = {} -- class {{{
-- VectorObject end }}}


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
        LuaUnit:run("GeneticManagerTest")
        LuaUnit:run("PPMImageTest")
    else
        error("Unknown operation")
    end
end --}}}

main(...)

-- vim: ts=4:expandtab:foldmethod=marker
