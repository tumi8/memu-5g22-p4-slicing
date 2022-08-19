local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local log    = require "log"

-- set addresses here
local SRC_MAC       = "11:22:33:44:55:66"
local DST_MAC_LOAD  = "AA:BB:CC:DD:EE:FF"
local DST_MAC_TS    = "AA:BB:CC:DD:EE:FE"
local SRC_IP        = "10.0.0.1"
local DST_IP        = "10.0.0.2"
local SRC_PORT      = 20000
local DST_PORT      = 21000


local VLANS 	    = {}

function configure(parser)
	parser:description("Generates UDP traffic and measure latencies.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:argument("vlan", "VLAN ID for packets."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-t --threads", "Number load generating threads."):default(1):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(84):convert(tonumber)
	parser:option("--samples", "Number of timestamps to record."):default(10000):convert(tonumber)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = args.threads + 1, txQueues = args.threads + 1}
	rxDev = device.config{port = args.rxDev, rxQueues = 2, txQueues = 2}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
	local rate_per_queue = (args.rate - (args.size + 4) * 8 / 1000) / args.threads
	for i = 0, args.threads - 1, 1 do
		txDev:getTxQueue(i):setRate(rate_per_queue, args.size)
	end
	mg.setRuntime(100) -- Force quit after 5 minutes


	mg.startTask("loadMaster", txDev:getTxQueue(0), rxDev, args.vlan, args.size, args.flows)
	for i = 1, args.threads - 1, 1 do
		mg.startTask("loadSlave", txDev:getTxQueue(i), rxDev, args.vlan, args.size, args.flows)
	end
	ts_task = mg.startTask("timerSlave", txDev:getTxQueue(args.threads), rxDev:getRxQueue(1), args.vlan, args.size, args.flows, args.samples)
	--mg.startTask("dumpSlave", rxDev:getRxQueue(0))

	ts_task:wait()
	log:info("Finished measurement, stopping traffic generator!")
	mg.stop()

end

local function fillVlanUdpPacket(buf, vlan, len)
	buf:getUdp4Packet():fill{
		ethSrc = SRC_MAC,
		ethDst = DST_MAC_LOAD,
		ethVlan = vlan,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

local function fillVlanUdpTSPacket(buf, vlan, len)
	buf:getUdp4Packet():fill{
		ethSrc = SRC_MAC,
		ethDst = DST_MAC_TS,
		ethVlan = vlan,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end

-- function dumpSlave(queue)
-- 	local bufs = memory.bufArray()
-- 	local pktCtr = stats:newPktRxCounter("Packets counted", "plain")
-- 	while mg.running() do
-- 		local rx = queue:tryRecv(bufs, 100)
-- 		for i = 1, rx do
-- 			local buf = bufs[i]
-- 			buf:dump()
-- 			pktCtr:countPacket(buf)
-- 		end
-- 		bufs:free(rx)
-- 		pktCtr:update()
-- 	end
-- 	pktCtr:finalize()
-- end

function loadMaster(queue, rxDev, vlan, size, flows, nVlans)

	local mempool = memory.createMemPool(function(buf)
		fillVlanUdpPacket(buf, vlan, size)
	end)
	local bufs = mempool:bufArray()
	local txCtr = stats:newDevTxCounter(queue, "CSV", "throughput-tx.csv")
	local rxCtr = stats:newDevRxCounter(rxDev, "CSV", "throughput-rx.csv")
	while mg.running() do
		bufs:alloc(size)
		queue:send(bufs)
		txCtr:update()
		rxCtr:update()
	end
	txCtr:finalize()
	rxCtr:finalize()
end

function loadSlave(queue, rxDev, vlan, size, flows, nVlans)

	local mempool = memory.createMemPool(function(buf)
		fillVlanUdpPacket(buf, vlan, size)
	end)
	local bufs = mempool:bufArray()
	while mg.running() do
		bufs:alloc(size)
		queue:send(bufs)
	end
end

function timerSlave(txQueue, rxQueue, vlan, size, flows, samples)

	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(3000) -- ensure that the load task is running
	local counter = 0
	local rateLimit = timer:new(0.001)
	while mg.running() and counter < samples do
		hist:update(timestamper:measureLatency(size, function(buf)
			fillVlanUdpTSPacket(buf, vlan, size)
			local pkt = buf:getUdpPacket()
			pkt.eth:setVlanTag(vlan)
		end))
		rateLimit:wait()
		rateLimit:reset()
		counter = counter + 1
	end
	-- print the latency stats after all the other stuff
	mg.sleepMillis(300)
	hist:print()
	hist:save("histogram.csv")
end

