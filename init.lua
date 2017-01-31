local mh = worldedit.manip_helpers


--- Adds a sphere of `node_name` centered at `pos`.
-- @param pos Position to center sphere at.
-- @param radius Sphere radius.
-- @param node_name Name of node to make shere of.
-- @param hollow Whether the sphere should be hollow.
-- @return The number of nodes added.
function worldedit.spherebrush(pos, radius, node_name, hollow)
	local manip, area = mh.init_radius(pos, radius)

	local data = mh.get_empty_data(area)

	-- Fill selected area with node
	local node_id = minetest.get_content_id(node_name)
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local stride_z, stride_y = area.zstride, area.ystride
	local count = 0
	for z = -radius, radius do
		-- Offset contributed by z plus 1 to make it 1-indexed
		local new_z = (z + offset_z) * stride_z + 1
		for y = -radius, radius do
			local new_y = new_z + (y + offset_y) * stride_y
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared <= max_radius and (not hollow or squared >= min_radius) then
					-- Position is on surface of sphere
					local i = new_y + (x + offset_x)
					data[i] = node_id
					count = count + 1
				end
			end
		end
	end

	mh.finish(manip, data)

	return
end

--[[

local brush_size = {
	{"Brush Tool: 1x."},
	{"Brush Tool: 2x."},
	{"Brush Tool: 4x."},
	{"Brush Tool: 6x."},
	{"Brush Tool: 8x."},
}
--]]

minetest.register_tool("brush_tool:brush", {
	description = "Brush Tool",
	inventory_image = "brush_tool_brush.png",
	stack_max = 1,
	wield_scale = {x=1,y=1,z=1},
        liquids_pointable = true,
	range = 12.0,
	    tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level=0,
		groupcaps={
		    -- For example:
		    fleshy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
		    snappy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
		    choppy={times={[3]=0.90}, maxwear=0.05, maxlevel=0}
		}
	},
	node_placement_prediction = nil,
        metadata = "default:dirt", -- default replacement: common dirt
	
	-- Right click
        on_place = function(itemstack, placer, pointed_thing)

       		if( placer == nil or pointed_thing == nil) then
	        return; end

       		if( pointed_thing.type ~= "node" ) then
          	minetest.chat_send_player( name, "  You are not pointing at a node.");
          	return nil; end
	
       		local name = placer:get_player_name();
	        local keys=placer:get_player_control();
       		local pos  = minetest.get_pointed_thing_position( pointed_thing, under );
       		local node = minetest.env:get_node_or_nil( pos );
    		local item = itemstack:to_table();
    
		if( not( minetest.check_player_privs(name, {worldedit=true}))) then
		return minetest.chat_send_player( name, "You don't have the worldedit priv." );
		end

       		if( not( keys["sneak"] )) then
		return 	worldedit.spherebrush(pos, tonumber(3), "default:steelblock", nil); end

       		-- make sure metadata is always set
       		if( node ~= nil and node.name ) then
          		item[ "metadata" ] = node.name..' '..node.param1..' '..node.param2;
       		else
          		item[ "metadata" ] = "default:dirt 0 0";
       		end
       		itemstack:replace( item );
	        minetest.chat_send_player( name, "Brush tool set to: '"..item[ "metadata" ].."'."); 
	        return itemstack; -- nothing consumed but data changed	
    	end,
     	on_use = function(itemstack, user, pointed_thing)
       		local pos  = minetest.get_pointed_thing_position( pointed_thing, under );
       		local name = user:get_player_name();

		if( not( minetest.check_player_privs(name, {worldedit=true}))) then
		return minetest.chat_send_player( name, "You don't have the worldedit priv." );
		end

	       	if( pointed_thing.type ~= "node" ) then
		  	minetest.chat_send_player( name, "  Error: Out of range.");
		  	return; end

		return worldedit.spherebrush(pos, tonumber(3), "air", nil);
--		worldedit.sphere(pos, radius, node_name, hollow)
--		return replacer.replace( itemstack, user, pointed_thing, above );
    	end,
})
