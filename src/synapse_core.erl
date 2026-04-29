-module(synapse_core).
-export([start/0, validate_transaction/2, collector/2]).

start() ->
    {ok, RawData} = file:read_file("data/input/transactions.dat"),
    Lines = string:tokens(erlang:binary_to_list(RawData), "\n"),
    
    {ok, OutDevice} = file:open("data/output/consensus_report.txt", [write]),
    io:format(OutDevice, "=======================================================~n", []),
    io:format(OutDevice, " ⚡ SYNAPSE DISTRIBUTED CONSENSUS ENGINE~n", []),
    io:format(OutDevice, "=======================================================~n~n", []),
    
    %% تشغيل المجمع الرئيسي (Collector Process)
    CollectorPid = spawn(?MODULE, collector, [length(Lines), OutDevice]),
    
    %% البساطة المرعبة: إنشاء "Process" مستقل لكل عملية مالية في نفس اللحظة!
    lists:foreach(fun(Line) -> 
        spawn(?MODULE, validate_transaction, [Line, CollectorPid]) 
    end, Lines),
    
    timer:sleep(1000), %% انتظار ثانية واحدة لتنتهي آلاف العمليات المتزامنة
    file:close(OutDevice),
    init:stop().

%% دالة التحقق: كل Process ينفذ هذه الدالة بشكل مستقل تماماً
validate_transaction(Line, CollectorPid) ->
    case length(Line) >= 15 of
        true ->
            TxID = string:substr(Line, 1, 8),
            Amount = list_to_integer(string:trim(string:substr(Line, 10))),
            if Amount > 50000 ->
                   CollectorPid ! {flagged, TxID, Amount};
               true ->
                   CollectorPid ! {cleared}
            end;
        false -> CollectorPid ! {error}
    end.

%% المجمع: يستقبل الرسائل من آلاف العمليات في وقت واحد
collector(0, OutDevice) -> 
    io:format(OutDevice, "~n[SYSTEM] ALL PROCESSES TERMINATED. CONSENSUS REACHED.~n", []);
collector(Remaining, OutDevice) ->
    receive
        {flagged, TxID, Amount} ->
            io:format(OutDevice, "[ALERT] CONCURRENT NODE DETECTED HIGH-VALUE TX: ~s ($~p)~n", [TxID, Amount]),
            collector(Remaining - 1, OutDevice);
        {cleared} ->
            collector(Remaining - 1, OutDevice);
        {error} ->
            collector(Remaining - 1, OutDevice)
    end.
