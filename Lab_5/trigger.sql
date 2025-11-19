-- Скрипт проверки корректности времени пары

CREATE OR REPLACE FUNCTION fix_timetable_time() RETURNS TRIGGER AS $$
    BEGIN
        -- время конца не раньше времени начала
        IF NEW.time_end <= NEW.time_begin THEN
            RAISE NOTICE 'Время начала % и время конца % автоматически поменяны местами.', NEW.time_begin, NEW.time_end;
            SELECT NEW.time_begin, NEW.time_end INTO NEW.time_end, NEW.time_begin;
        END IF;
        
        -- корпус в это время не работает
        IF NEW.time_end > '22:00:00' OR NEW.time_begin < '8:00:00' THEN
            RAISE EXCEPTION 'Университет в это время не работает.';
        END IF;

        -- в воскресенье может быть только экзамен 
        IF NEW.lesson_type != 'экзамен' AND NEW.day_of_week = 0 THEN
            RAISE EXCEPTION 'В воскресенье может проводиться только экзамен.';
        END IF;

        -- продолжительность меньше 1.5 часов
        IF (EXTRACT(EPOCH FROM (NEW.time_end - NEW.time_begin)) / 60) < 90 THEN
            RAISE NOTICE 'Продолжительность занятия автоматически скорректирована.';
            NEW.time_end := NEW.time_begin + INTERVAL '90 minutes';
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_fix_timetable_time
BEFORE INSERT OR UPDATE ON timetable
FOR EACH ROW
EXECUTE FUNCTION fix_timetable_time();