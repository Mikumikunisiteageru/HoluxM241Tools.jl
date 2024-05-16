# src/HoluxM241Tools.jl

module HoluxM241Tools

export gpsbin2tsv

using Dates
using Printf

const CHUNKSIZE = 65536
const EPOCH2SEC = Dates.value(Second(Week(1024))) # 619315200
const HOUR2SEC = Dates.value(Second(Hour(1))) # 3600

# GPS week number rollover
calibtime(utimeraw::Real, utimeref::Real) = 
	utimeref - mod(utimeref - utimeraw, EPOCH2SEC)
calibtime(utimeraw::Real, timeref::DateTime=now()) = 
	calibtime(utimeraw, datetime2unix(timeref))

struct Record
	utimeraw0::Int32
	time::DateTime
	latitude::Float32
	longitude::Float32
	altitude::Float32
	velocity::Float32
	checkbit::UInt8
	function Record(icosabyte::AbstractVector{UInt8}; 
			timezone::Real=+8, timeref=now())
		utimeraw0, = reinterpret(Int32, icosabyte[1:4])
		utimeraw   = utimeraw0 + timezone * HOUR2SEC
		time       = unix2datetime(calibtime(utimeraw, timeref))
		latitude,  = reinterpret(Float32, icosabyte[5:8])
		longitude, = reinterpret(Float32, icosabyte[9:12])
		altitude,  = reinterpret(Float32, icosabyte[12:15])
		velocity,  = reinterpret(Float32, icosabyte[16:19])
		checkbit   = reduce(xor, icosabyte)
		return new(utimeraw0, time, 
			latitude, longitude, altitude, velocity, checkbit)
	end
end

function extrecords(chunk::AbstractVector{UInt8}; 
		timezone::Real=+8, timeref=now())
	records = Record[]
	i = 513                       # discard the starting 512-byte rubbish
	while i <= CHUNKSIZE - 19
		if chunk[i:i+3] == [0xAA, 0xAA, 0xAA, 0xAA]
			i += 16               # discard 16-byte rubbish from 0xAAAAAAAA
		elseif chunk[i+16:i+19] == [0x20, 0x20, 0x20, 0x20]
			i += 20               # discard 20-byte rubbish to 0x20202020
		elseif chunk[i:i+3] == [0xFF, 0xFF, 0xFF, 0xFF]
			break                 # discard rubbish region padded with 0xFF
		else
			push!(records, Record(chunk[i:i+19]; 
				timezone=timezone, timeref=timeref))
			i += 20               # collect a valid record
		end
	end
	return records
end

function extrecords(finname::AbstractString; timezone::Real=+8, timeref=now())
	data = read(finname)
	chunks = Iterators.partition(data, CHUNKSIZE)
	return reduce(vcat, extrecords.(chunks; timezone=timezone, timeref=timeref))
end

printrecords(foutname::AbstractString, records::AbstractVector{Record}) = 
	open(foutname, "w") do fout
		for (i, record) = enumerate(records)
			write(fout, join([i, record.utimeraw0, 
				Dates.format(record.time, "YYYY-mm-dd,HH:MM:SS"), 
				@sprintf("%.6f", record.latitude), 
				@sprintf("%.6f", record.longitude), 
				@sprintf("%.1f", record.altitude), 
				@sprintf("%.3f", record.velocity), 
				record.checkbit], '\t'), '\n')
		end
	end

gpsbin2tsv(finname::AbstractString, foutname::AbstractString; 
	timezone::Real=+8, timeref=now()) = 
		printrecords(foutname, 
			extrecords(finname; timezone=timezone, timeref=timeref))

end # module HoluxM241Tools
