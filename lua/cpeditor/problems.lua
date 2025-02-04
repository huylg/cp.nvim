local M = {
	current_problem = nil,
	problemList = {},
}

local path = require "plenary.path"
local config = require("cpeditor").config

local function parse_link(url)
	local res = nil
	for link, dir in pairs(config.links) do
		local match = (url):gmatch(link)
		for k, v in match do
			res = { k, v, dir }
		end
		if res then -- Avoid luacheck
			return res
		end
	end
end

function M.switch(index)
	M.current_problem = M.problemList[index]
end

function M.build_test(tests, problem_path)
	local problem = M.current_problem
	problem_path = problem_path:joinpath "tests"
	for i, test in pairs(tests) do
		problem.result[i] = "NA"
		i = tostring(i)
		problem_path:joinpath(i):mkdir { exists_ok = true, parents = true }
		problem_path:joinpath(i, i .. ".in"):write(test.input, "w")
		problem_path:joinpath(i, i .. ".ans"):write(test.output, "w")
	end
end

function M.new(data)
	local k, v, dir = unpack(parse_link(data.url))
	local contest_dir = path:new(dir)
	contest_dir = path:new(contest_dir:expand())
	local problem_path = contest_dir:joinpath(k, v)
	problem_path:mkdir { exists_ok = true, parents = true }
	local problem_name = k .. v
	for _, p in ipairs(M.problemList) do
		if p.name == problem_name then
			vim.api.nvim_set_current_tabpage(p.tab_id)
			return
		end
	end
	M.current_problem = {
		name = problem_name,
		path = problem_path.filename,
		timeout = data.timeLimit,
		curTest = 1,
		result = {},
	}
	table.insert(M.problemList, M.current_problem)
	local problem = M.current_problem
	M.build_test(data.tests, problem_path)
	if #M.problemList ~= 1 then
		vim.cmd "$tabnew"
	end
	problem.tab_id = vim.api.nvim_get_current_tabpage()
	vim.t.cp_problem_name = problem_name
	vim.cmd("tcd " .. problem.path)
	require("cpeditor.layout").change()
end

return M
