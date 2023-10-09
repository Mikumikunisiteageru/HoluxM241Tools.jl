# test/runtests.jl

using Aqua
using Dates
using HoluxM241Tools
using Test

Aqua.test_all(HoluxM241Tools)

@testset "calibtime" begin
	calibtime = HoluxM241Tools.calibtime
	@test calibtime(123456789, 1555954816) === 1362087189
	@test calibtime(123456789, 1555954816.0) === 1362087189.0
	@test calibtime(123456789.0, 1555954816) === 1362087189.0
	@test calibtime(123456789.0, 1555954816.0) === 1362087189.0
	timeref = DateTime(2019, 4, 22, 17, 40, 16)
	@test calibtime(123456789, timeref) === 1362087189.0
	@test calibtime(123456789.0, timeref) === 1362087189.0
end

@testset "Record" begin
	Record = HoluxM241Tools.Record
	icosabyte = [0xCD, 0xD0, 0xFB, 0x3F, 0x45, 0xE5, 0x1F, 0x42, 0x32, 0x76, 
				 0xE8, 0x42, 0x8B, 0x6A, 0x42, 0x9C, 0xCD, 0x12, 0x3E, 0x14]
	timezone = +8
	timeref = DateTime(2023, 8, 31, 20, 20, 39)
	record = Record(icosabyte; timezone=timezone, timeref=timeref)
	@test isa(record, Record)
	@test record.utimeraw0 === Int32(1073467597)
	@test record.time === DateTime(2023, 8, 23, 17, 26, 37)
	@test record.latitude === 39.973896f0
	@test record.longitude === 116.23085f0
	@test record.altitude === 58.635994f0
	@test record.velocity === 0.14336246f0
	@test record.checkbit === 0x00
end

@testset "gpsbin2tsv" begin
	finname = "gps.bin"
	foutname = joinpath(tempdir(), "gps.tsv")
	isfile(foutname) && rm(foutname)
	timeref = DateTime(2023, 8, 31, 20, 20, 39)
	@test nothing === gpsbin2tsv(finname, foutname; timeref=timeref)
	outlines = read(foutname)
	outlinesref = read("gps.tsv")
	@test outlines == outlinesref
	rm(foutname)
end
