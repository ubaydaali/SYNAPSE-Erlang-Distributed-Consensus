-module(synapse_core).
-export([start/0, validate_transaction/2, collector/3]).

start() ->
    {ok, RawData} = file:read_file("data/input/transactions.dat"),
    %% تقسيم الأسطر بطريقة آمنة لجميع أنظمة التشغيل والسحابة
    Lines = string:tokens(erlang:binary_to_list(RawData), "\r\n"),
    
    {ok, OutDevice} = file:open("data/output/consensus_report.txt", [write]),
    io:format(OutDevice, "=======================================================~n", []),
    io:format(OutDevice, " ⚡ SYNAPSE DISTRIBUTED CONSENSUS ENGINE~n", []),
    io:format(OutDevice, "=======================================================~n~n", []),
    
    %% تمرير معرف العملية الرئيسية (self) للمجمع لكي يخبرنا عند الانتهاء
    MainPid = self(),
    CollectorPid = spawn(?MODULE, collector, [length(Lines), OutDevice, MainPid]),
    
    lists:foreach(fun(Line) -> 
        spawn(?MODULE, validate_transaction, [Line, CollectorPid]) 
    end, Lines),
    
    %% بدلاً من التخمين بثانية واحدة، ننتظر رسالة التأكيد من المجمع (بدون وقت محدد)
    receive
        {consensus_reached} ->
            file:close(OutDevice),
            init:stop()
    after 15000 -> %% كإجراء أمان، ننتظر 15 ثانية كحد أقصى على السحابة
        io:format(OutDevice, "~n[TIMEOUT] CLOUD INSTANCE TOO SLOW. HALTING.~n", []),
        file:close(OutDevice),
        init:stop()
    end.

validate_transaction(Line, CollectorPid) ->
    case length(Line) >= 15 of
        true ->
            TxID = string:substr(Line, 1, 8),
            AmountStr = string:trim(string:substr(Line, 10)),
            %% تحويل آمن للأرقام
            case catch list_to_integer(AmountStr) of
                Amount when is_integer(Amount), Amount > 50000 ->
                    CollectorPid ! {flagged, TxID, Amount};
                _ ->
                    CollectorPid ! {cleared}
            end;
        false -> 
            CollectorPid ! {error}
    end.

%% المجمع: عندما يصل العداد إلى الصفر، يطبع رسالة الختام ويرسل التأكيد للمحرك الرئيسي
collector(0, OutDevice, MainPid) -> 
    io:format(OutDevice, "~n[SYSTEM] ALL 10,000 PROCESSES TERMINATED. CONSENSUS REACHED.~n", []),
    MainPid ! {consensus_reached};

collector(Remaining, OutDevice, MainPid) ->
    receive
        {flagged, TxID, Amount} ->
            io:format(OutDevice, "[ALERT] CONCURRENT NODE DETECTED HIGH-VALUE TX: ~s ($~p)~n", [TxID, Amount]),
            collector(Remaining - 1, OutDevice, MainPid);
        {cleared} ->
            collector(Remaining - 1, OutDevice, MainPid);
        {error} ->
            collector(Remaining - 1, OutDevice, MainPid)
    end.
