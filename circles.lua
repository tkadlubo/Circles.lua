#!/usr/bin/env lua

Encoder = {} -- class {{{
function Encoder:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
-- Encoder end }}}

Decoder = {} -- class {{{
-- Decoder end }}}

Palette = {} -- class {{{
-- Palette end }}}

VectorImage = {} -- class {{{
-- VectorObject end }}}

PPMImage = {} -- class {{{
function PPMImage:new(o, image)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Init data from PPM image file 
    if type(image) == "string" then
    -- Init data by rendering a VectorImage
    o:readPPMFile(image)
    elseif type(image) == "table" then
    end
    return o
end

function PPMImage:readPPMFile(fileName)
    local file = io.open(fileName, "r")
    assert(file ~= nil)

    self.parserState = "start"

    local parserStateMachine = {
        start = function(self, line)
            if line ~= "P3" then
                error("PPM syntax error in line "..self.line_counter..": only P3 format supported")
            end
            self.parserState = "aspectRatio"
        end,
        aspectRatio = function(self, line)
            local width, height = line:match("(%d+) (%d+)")
            if width ~= nil and height ~=nil then
                self.width = tonumber(width)
                self.height = tonumber(height)
            else
                error("PPM syntax error in line "..self.line_counter..": invalid image size")
            end
            self.parserState = "colorDepth"
        end,
        colorDepth = function(self, line)
            if line ~= "255" then
                error("PPM syntax error in line "..self.line_counter..": only 24bit images are supported")
            end
            self.parserState = "pixelData"
        end,
        pixelData = function(self, line)
        end
    }
    self.line_counter = 0
    for line in file:lines() do
        self.line_counter = self.line_counter + 1
        if line:sub(1, 1) ~= "#" then
            parserStateMachine[self.parserState](self, line)
        end
    end

    file:close()
end

function PPMImage:aspectRatio()
    return {self.width, self.height}
end
-- PPMImage end }}}

PPMImageTest = {} -- class {{{
function PPMImageTest:setUp()
    self.testedImage = PPMImage:new({}, "test.ppm")
end

function PPMImageTest:testConstructor()
    assertEquals(type(self.testedImage), "table")
end

function PPMImageTest:testFileData()
end

function PPMImageTest:testAspectRatio()
    local aspectRatio = self.testedImage:aspectRatio()
    assertEquals(aspectRatio[1], 3)
    assertEquals(aspectRatio[2], 2)
end

-- PPMImageTest end }}}

GeneticManager = {} -- class {{{
-- GeneticManager end }}}

function main(operation, inputFile, outputFile) --{{{

    if operation == "encode" then
        if inputFile == nil or outputFile == nil then
            error("Invalid command line parameters")
        end
        encoder = Encoder:new()
        inputImage = PPMImage:new(inputFile)
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
        LuaUnit:run("PPMImageTest")
    else
        error("Unknown operation")
    end
end --}}}

main(...)

-- vim: ts=4:expandtab:foldmethod=marker
