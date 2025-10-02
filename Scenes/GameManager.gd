extends Node

var money: int = 100

signal money_changed(new_money)

func add_money(amount: int):
	money += amount
	emit_signal("money_changed", money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false
