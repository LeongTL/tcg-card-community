-- Dev seed: 30 real TCGdex cards (every foil style), 5 users and a few listings.

insert into catalog.cards (id, name, set_id, set_name, number, rarity, hp, image_url, foil_style) values
  ('sv06.5-090', 'Okidogi ex', 'sv06.5', 'Shrouded Fable', '090', 'Special illustration rare', 250, 'https://assets.tcgdex.net/en/sv/sv06.5/090/high.webp', 'sir'),
  ('sv03.5-199', 'Charizard ex', 'sv03.5', '151', '199', 'Special illustration rare', 330, 'https://assets.tcgdex.net/en/sv/sv03.5/199/high.webp', 'sir'),
  ('sv04.5-234', 'Charizard ex', 'sv04.5', 'Paldean Fates', '234', 'Special illustration rare', 330, 'https://assets.tcgdex.net/en/sv/sv04.5/234/high.webp', 'sir'),
  ('sv06.5-065', 'Tapu Bulu', 'sv06.5', 'Shrouded Fable', '065', 'Illustration rare', 140, 'https://assets.tcgdex.net/en/sv/sv06.5/065/high.webp', 'alt'),
  ('sv06.5-066', 'Houndoom', 'sv06.5', 'Shrouded Fable', '066', 'Illustration rare', 120, 'https://assets.tcgdex.net/en/sv/sv06.5/066/high.webp', 'alt'),
  ('sv03-125', 'Charizard ex', 'sv03', 'Obsidian Flames', '125', 'Double rare', 330, 'https://assets.tcgdex.net/en/sv/sv03/125/high.webp', 'ultra'),
  ('sv07-001', 'Venusaur ex', 'sv07', 'Stellar Crown', '001', 'Double rare', 340, 'https://assets.tcgdex.net/en/sv/sv07/001/high.webp', 'ultra'),
  ('swsh9-018', 'Charizard VSTAR', 'swsh9', 'Brilliant Stars', '018', 'Holo Rare VSTAR', 280, 'https://assets.tcgdex.net/en/swsh/swsh9/018/high.webp', 'ultra'),
  ('swsh1-1', 'Celebi V', 'swsh1', 'Sword & Shield', '1', 'Holo Rare V', 180, 'https://assets.tcgdex.net/en/swsh/swsh1/1/high.webp', 'ultra'),
  ('sm9-1', 'Celebi & Venusaur GX', 'sm9', 'Team Up', '1', 'Ultra Rare', 270, 'https://assets.tcgdex.net/en/sm/sm9/1/high.webp', 'ultra'),
  ('base1-4', 'Charizard', 'base1', 'Base Set', '4', 'Rare', 120, 'https://assets.tcgdex.net/en/base/base1/4/high.webp', 'holo'),
  ('base2-1', 'Clefable', 'base2', 'Jungle', '1', 'Rare', 70, 'https://assets.tcgdex.net/en/base/base2/1/high.webp', 'holo'),
  ('neo1-9', 'Lugia', 'neo1', 'Neo Genesis', '9', 'Rare', 90, 'https://assets.tcgdex.net/en/neo/neo1/9/high.webp', 'holo'),
  ('dp1-1', 'Dialga', 'dp1', 'Diamond & Pearl', '1', 'Rare Holo', 90, 'https://assets.tcgdex.net/en/dp/dp1/1/high.webp', 'holo'),
  ('swshp-SWSH020', 'Pikachu', 'swshp', 'SWSH Black Star Promos', 'SWSH020', 'Promo', 70, 'https://assets.tcgdex.net/en/swsh/swshp/SWSH020/high.webp', 'holo'),
  ('sv06.5-095', 'Pecharunt ex', 'sv06.5', 'Shrouded Fable', '095', 'Hyper rare', 190, 'https://assets.tcgdex.net/en/sv/sv06.5/095/high.webp', 'gold'),
  ('sv06.5-096', 'Earthen Vessel', 'sv06.5', 'Shrouded Fable', '096', 'Hyper rare', null, 'https://assets.tcgdex.net/en/sv/sv06.5/096/high.webp', 'gold'),
  ('me05-120', 'Mega Darkrai ex', 'me05', 'Pitch Black', '120', 'Mega Hyper Rare', 280, 'https://assets.tcgdex.net/en/me/me05/120/high.webp', 'gold'),
  ('sv04.5-092', 'Oddish', 'sv04.5', 'Paldean Fates', '092', 'Shiny rare', 60, 'https://assets.tcgdex.net/en/sv/sv04.5/092/high.webp', 'shiny'),
  ('sv04.5-212', 'Forretress ex', 'sv04.5', 'Paldean Fates', '212', 'Shiny Ultra Rare', 270, 'https://assets.tcgdex.net/en/sv/sv04.5/212/high.webp', 'shiny'),
  ('dp3-1', 'Ampharos', 'dp3', 'Secret Wonders', '1', 'Rare Holo', 130, 'https://assets.tcgdex.net/en/dp/dp3/1/high.webp', 'cosmos'),
  ('svp-001', 'Sprigatito', 'svp', 'SVP Black Star Promos', '001', 'Promo', 70, 'https://assets.tcgdex.net/en/sv/svp/001/high.webp', 'cosmos'),
  ('ex6-100', 'VS Seeker', 'ex6', 'FireRed & LeafGreen', '100', 'Uncommon', null, 'https://assets.tcgdex.net/en/ex/ex6/100/high.webp', 'reverse'),
  ('me01-001', 'Bulbasaur', 'me01', 'Mega Evolution', '001', 'Common', 80, 'https://assets.tcgdex.net/en/me/me01/001/high.webp', 'reverse'),
  ('sv08-001', 'Exeggcute', 'sv08', 'Surging Sparks', '001', 'Common', 30, 'https://assets.tcgdex.net/en/sv/sv08/001/high.webp', 'reverse'),
  ('sv01-001', 'Pineco', 'sv01', 'Scarlet & Violet', '001', 'Common', 60, 'https://assets.tcgdex.net/en/sv/sv01/001/high.webp', 'reverse'),
  ('base1-58', 'Pikachu', 'base1', 'Base Set', '58', 'Common', 40, 'https://assets.tcgdex.net/en/base/base1/58/high.webp', 'plain'),
  ('xy12-11', 'Charizard', 'xy12', 'Evolutions', '11', 'Rare', 150, 'https://assets.tcgdex.net/en/xy/xy12/11/high.webp', 'plain'),
  ('sm1-1', 'Caterpie', 'sm1', 'Sun & Moon', '1', 'Common', 50, 'https://assets.tcgdex.net/en/sm/sm1/1/high.webp', 'plain'),
  ('bw1-1', 'Snivy', 'bw1', 'Black & White', '1', 'Common', 60, 'https://assets.tcgdex.net/en/bw/bw1/1/high.webp', 'plain')
on conflict (id) do nothing;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-000000000001', 'user1@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'user2@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'user3@example.test'),
  ('00000000-0000-0000-0000-000000000004', 'user4@example.test'),
  ('00000000-0000-0000-0000-000000000005', 'user5@example.test')
on conflict (id) do nothing;

insert into identity.profiles (id, display_name, city, verification_level) values
  ('00000000-0000-0000-0000-000000000001', 'Aiman', 'Kuala Lumpur', 1),
  ('00000000-0000-0000-0000-000000000002', 'Siti', 'Kuala Lumpur', 1),
  ('00000000-0000-0000-0000-000000000003', 'Wei Jie', 'Kuala Lumpur', 1),
  ('00000000-0000-0000-0000-000000000004', 'Priya', 'Kuala Lumpur', 0),
  ('00000000-0000-0000-0000-000000000005', 'Daniel', 'Kuala Lumpur', 0)
-- the sign-up trigger already made empty profile rows for the users above
on conflict (id) do update set display_name = excluded.display_name, city = excluded.city,
  verification_level = excluded.verification_level;

insert into identity.user_flags (user_id) select id from identity.profiles on conflict do nothing;

insert into listings.collection_items (id, owner_id, card_id, condition, status) values
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'base1-4', 'NM', 'open_to_sell'),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000002', 'sv03.5-199', 'NM', 'open_to_sell'),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000003', 'swsh9-018', 'LP', 'open_to_sell'),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'sv06.5-090', 'NM', 'open_to_sell'),
  ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000002', 'ex6-100', 'NM', 'showcase')
on conflict (id) do nothing;

insert into listings.listings (id, item_id, seller_id, card_id, price, type, status) values
  ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'base1-4', 250, 'sell', 'active'),
  ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000002', 'sv03.5-199', 180, 'sell', 'active'),
  ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000003', 'swsh9-018', 45, 'sell', 'active'),
  ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'sv06.5-090', 320, 'sell', 'active')
on conflict (id) do nothing;
