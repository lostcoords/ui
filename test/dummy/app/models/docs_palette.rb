module DocsPalette
  Palette = Data.define(:id, :name, :number, :colors)

  ALL = [
    Palette.new(id: "original", name: "Default", number: nil, colors: []),
    Palette.new(id: "ivory-blue", name: "Ivory & blue", number: 126, colors: [ "Ivory Buff", "Yellow Ocher", "Deep Lyons Blue" ]),
    Palette.new(id: "coral-green", name: "Coral & green", number: 166, colors: [ "Grenadine Pink", "Naples Yellow", "Deep Slate Green" ]),
    Palette.new(id: "rose", name: "Rose & garnet", number: 273, colors: [ "Hermosa Pink", "Pansy Purple", "Sudan Brown", "Neutral Gray" ]),
    Palette.new(id: "earth", name: "Earth & ink", number: 343, colors: [ "Burnt Sienna", "Ivory Buff", "Deep Grayish Olive", "Vandar Poel's Blue" ]),
    Palette.new(id: "olive", name: "Olive & violet", number: 348, colors: [ "Olive Buff", "Cossack Green", "Deep Slate Olive", "Cotinga Purple" ])
  ].freeze
end
