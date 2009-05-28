#!/usr/bin/env lua

Encoder = {} -- class
function Encoder:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
-- Encoder end

Decoder = {} -- class
-- Decoder end

Palette = {} -- class
-- Palette end

VectorImage = {} -- class
-- VectorObject end

PPMImage = {} -- class
function PPMImage:new(o, image)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Init data from PPM image file 
    if type(image) == "string" then
    -- Init data 
    elseif type(image) == "table" then
    end
    return o
end

-- PPMImage end


GeneticManager = {} -- class
-- GeneticManager end

function main(operation, inputFile, outputFile)
    if inputFile == nil or outputFile == nil then
        error("Invalid command line parameters")
    end

    if operation == "encode" then
        encoder = Encoder:new()
        inputImage = PPMImage:new(inputFile)
        outputImage = encoder:encode(inputImage)
        outputImage.writeTwit(outputFile)
        return
    elseif operation == "decode" then
        decoder = Decoder:new()
        inputImage = decoder.readTwit(inputFile)
        outputImage = PPMImage:new(inputImage)
        outputImage.write(outputFile)
        return
    end

    error("Unknown operation")
end
main(...)

-- vim: ts=4:expandtab
