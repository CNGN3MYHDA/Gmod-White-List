local PANEL = {}

function PANEL:Init()
	self.VBar:SetHideButtons(true)
	self.VBar:SetWide(5)
	self.VBar.Paint = nil
	self.VBar.btnGrip.Paint = function(self, w, h)
		draw.RoundedBox(20, 0, -w, w, h+w*2, Color(50, 50, 50))
	end
end

derma.DefineControl("BWL_Scroll", "White list menu scroll panel", PANEL, "DScrollPanel")