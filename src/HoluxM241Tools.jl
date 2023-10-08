# src/HoluxM241Tools.jl

module HoluxM241Tools

using Dates

const CHUNKSIZE = 65536

function readdata(filename::AbstractString)
	return open(filename, "r") do fin
		read(fin)
	end
end

function exrecords(chunk::AbstractVector{UInt8})
	intvstarts = Int[]
	i = 513
	while i <= CHUNKSIZE - 19
		if chunk[i:i+3] == [0xAA, 0xAA, 0xAA, 0xAA]
			i += 16               # discard 16-byte rubbish from 0xAAAAAAAA
		elseif chunk[i+16:i+19] == [0x20, 0x20, 0x20, 0x20]
			i += 20               # discard 20-byte rubbish to 0x20202020
		elseif chunk[i:i+3] == [0xFF, 0xFF, 0xFF, 0xFF]
			break                 # discard rubbish region padded with 0xFF
		else
			push!(intvstarts, i)  # collect valid record
			i += 20
		end
	end
	return Iterators.map(i -> chunk[i:i+19], intvstarts)
end

struct Record
	time::DateTime
	latitude::Float32
	longitude::Float32
	altitude::Float32
	velocity::Float32
	checkbit::UInt8
	function Record(icosabyte::AbstractVector{UInt8}, timezone::Integer=+8)
		unixtime, = reinterpret(Int32, icosabyte[1:4])
		time = unix2datetime(unixtime) + Hour(timezone)
		latitude, = reinterpret(Float32, icosabyte[5:8])
		longitude, = reinterpret(Float32, icosabyte[9:12])
		altitude, = reinterpret(Float32, icosabyte[12:15])
		velocity, = reinterpret(Float32, icosabyte[16:19])
		checkbit = reduce(xor, icosabyte)
		return new(time, latitude, longitude, altitude, velocity, checkbit)
	end
end

for chunk = Iterators.partition(bytes, CHUNKSIZE)
	records = exrecords(chunk)
end

end # module HoluxM241Tools
