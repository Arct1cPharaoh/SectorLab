local Controls = {}

Controls.list = {
    {
        name = 'reset',
        label = 'Reset to section start',
        button = ac.ControlButton('__APP_SECTORLAB_RESET')
    },
    {
        name = 'nextSection',
        label = 'Next section',
        button = ac.ControlButton('__APP_SECTORLAB_NEXT')
    },
    {
        name = 'previousSection',
        label = 'Previous section',
        button = ac.ControlButton('__APP_SECTORLAB_PREVIOUS')
    },
    {
        name = 'setStart',
        label = 'Creator: Set start here',
        button = ac.ControlButton('__APP_SECTORLAB_SET_START')
    },
    {
        name = 'setFinish',
        label = 'Creator: Set finish here',
        button = ac.ControlButton('__APP_SECTORLAB_SET_FINISH')
    },
}

for _, control in ipairs(Controls.list) do
    Controls[control.name] = control.button
end

-- Draws a  "label [binding box]" row
function Controls.drawBindings()
    for _, control in ipairs(Controls.list) do
        ui.text(control.label)
        ui.sameLine(180)
        control.button:control(vec2(160, 0))
    end
end

return Controls
