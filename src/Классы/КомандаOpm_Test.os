///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Выполнить тестирование проекта");
	Парсер.ДобавитьПараметрКоллекцияКоманды(ОписаниеКоманды, "ПараметрыЗадачи", "Коллекция параметров, передаваемых задаче тестирования");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	ВыполнитьЗадачу("test", ПараметрыКоманды["ПараметрыЗадачи"]);
	Возврат 0;
	
КонецФункции

Процедура ВыполнитьЗадачу(Знач ИмяЗадачи, Знач ПараметрыЗадачи) 
	
	ИсполнительЗадач = Новый ИсполнительЗадач();
	ИсполнительЗадач.ВыполнитьЗадачу(ИмяЗадачи, ПараметрыЗадачи);
	
КонецПроцедуры