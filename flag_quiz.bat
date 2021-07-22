::------------------------------------------------------------------------------
:: NAME
::     FlagQuiz
::
:: DESCRIPTION
::     A quiz about different tricolor world flags, displayed in a 24x6 box.
::     Based on flag.bat by Taken48
:: 
:: AUTHOR
::     Sintrode
::
:: THANKS
::     wikipedia.org/wiki/List_of_national_flags_by_design
::     flagcolor.com
::
:: VERSION HISTORY
::     1.2 (2021-06-14) - Replaced extended ASCII with DEC Line Drawing
::     1.1 (2021-06-12) - Removed ability for questions to repeat
::     1.0 (2021-06-12) - Initial Version
::------------------------------------------------------------------------------
@echo off
setlocal enabledelayedexpansion
mode con cols=28 lines=15

:: Initialize data
set "flag_pack=%~dp0\data.txt"
if not exist "%flag_pack%" (
    echo [31mERROR[0m: %flag_pack% could not be found. Exiting.
    exit /b 1
)

:: We're starting at zero and incrementing afterwards so that rd_counter
:: is 1 greater than the actual number of questions. This way, we can
:: use !RANDOM!%%!rd_counter! to pick a question without doing extra math.
set rd_counter=0
for /f "usebackq delims=" %%A in ("%flag_pack%") do (
    set "raw_data[!rd_counter!]=%%A"
    set /a rd_counter+=1
)

:: We only need to disable the blinking cursor once
echo [?25l

:: The if statement after picking an answer checks if the input is incorrect,
:: so we're assuming that the player gets everything right by default and then
:: we subtract a point when they miss.
set "score=!rd_counter!"

if exist debug.txt del debug.txt
:display_area


cls
echo (0
echo  lqqqqqqqqqqqqqqqqqqqqqqqqk
echo  x                        x
echo  x                        x
echo  x                        x
echo  x                        x
echo  x                        x
echo  x                        x
echo  tqqqqqqqqqqqqqqqqqqqqqqqqu
echo  tqqqu                tqqqu
echo  tqqqu                tqqqu
echo  tqqqu                tqqqu
echo  mqqqqqqqqqqqqqqqqqqqqqqqqj(B

:show_question
:: Pick a random question
set /a question=!RANDOM!%%!rd_counter!
if not defined raw_data[%question%] (
	set questions_left=0
	for /L %%A in (0,1,!rd_counter!) do if defined raw_data[%%A] set /a questions_left+=1
	if "!questions_left!"=="0" goto :game_over
	goto :show_question
)
for /f "tokens=1-4* delims=," %%A in ("!raw_data[%question%]!") do (
    set "stripe_direction=%%~A"
    set "color1_RGB=%%~B"
    set "color2_RGB=%%~C"
    set "color3_RGB=%%~D"
    set "answer_set=%%~E"
)
call :scramble "!answer_set!"
call :draw_flag
for /L %%A in (1,1,3) do (
    set /a answer_row=%%A+9
    echo [!answer_row!;7H%%A. !answer[%%A]!
)
choice /C:123 /N >nul
if not "!ERRORLEVEL!"=="%correct_option%" (
    set /a selection_row=!ERRORLEVEL!+9
    echo [!selection_row!;10H[31m!answer[%errorlevel%]![0m
	set /a score-=1
)
set /a correct_row=%correct_option%+9
echo [!correct_row!;10H[32m!answer[%correct_option%]![0m
echo [14;2H
timeout /t 2 >nul

set "raw_data[%question%]="
for /L %%A in (1,1,!rd_counter!) do if defined raw_data[%%A] goto :display_area

:game_over
mode con cols=80 lines=25
echo [?25h
echo FINAL SCORE: !score!/!rd_counter!
exit /b


::------------------------------------------------------------------------------
:: Draws a 24x6 tricolor rectangle inside of a frame
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:draw_flag
:: The flag is actually made up of nine boxes. The top-left box is always
:: color1, the middle box is always color2, and the bottom-right box is always
:: color3. The remaining boxes vary based on stripe direction.

set "base_box=        [B[8D        [A"
set "pattern_h=1 1 1 2 2 2 3 3 3"
set "pattern_v=1 2 3 1 2 3 1 2 3"

set box_counter=0
for %%A in (!pattern_%stripe_direction%!) do (
    set /a box_counter+=1
    set "box_!box_counter!=[48;2;!color%%A_RGB!m%base_box%[0m"
)
echo [3;3H%box_1%%box_2%%box_3%
echo [5;3H%box_4%%box_5%%box_6%
echo [7;3H%box_7%%box_8%%box_9%
exit /b

::------------------------------------------------------------------------------
:: Takes a comma-delimited string of three items and rearranges them in a
:: random order so that users have to memorize the answer and not the letter.
::
:: Arguments: %1 - A string in the format correct,incorrect,incorrect
:: Returns:   %correct_option% - The index of the actual answer
::            %answer[1]%      - The first answer to display
::            %answer[2]%      - The second answer to display
::            %answer[3]%      - The third answer to display
::------------------------------------------------------------------------------
:scramble
for /f "tokens=1-3 delims=," %%A in ("%~1") do (
    set "correct_answer=%%~A"
    set "answer[1]=%%~A"
    set "answer[2]=%%~B"
    set "answer[3]=%%~C"
)

:: Ideally we'd pick two random elements and switch them, but since we only
:: have three choices, swapping the first element with either the second or
:: third one is good enough.
for /L %%A in (1,1,10) do (
    set /a switch_1_with=!RANDOM!%%2+2
    for /f %%B in ("!switch_1_with!") do (
        set "tmp_ans=!answer[1]!"
        set "answer[1]=!answer[%%B]!"
        set "answer[%%B]=!tmp_ans!"
    )
)

for /L %%A in (1,1,3) do (
    if "!answer[%%A]!"=="%correct_answer%" set "correct_option=%%A"
)
exit /b
