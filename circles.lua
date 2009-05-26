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

ImageObject = {} -- class
function ImageObject:renderToBMP(imageBMP)
end
-- ImageObject end

Image = {} -- class
function Image:renderToBMP()
    
end

-- Image end

GeneticManager = {} -- class
-- GeneticManager end

function main(operation, inputFile, outputFile)
    if inputFile == nil or outputFile == nil then
        error("Invalid command line parameters")
    end

    if operation == "encode" then
        return
    elseif operation == "decode" then
        return
    end

    error("Unknown operation")
main(...)

-- vim: ts=4:expandtab
