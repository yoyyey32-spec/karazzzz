spawn(function()
	while true do
		if game:GetService("Players").LocalPlayer:FindFirstChild("Recoil") then
			game:GetService("Players").LocalPlayer.Recoil:Destroy()
		end
		wait(0.2) -- increased delay to prevent freezing
	end
end)
