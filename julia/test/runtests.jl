using MlxtranTypst
using Test

const M = MlxtranTypst

@testset "MlxtranTypst" begin
    @testset "operator precedence" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = a + b*c") == "\$y = a + b dot c\$"
        @test M.mlxtran_to_typst("EQUATION:\ny = 10^a^b*c") == "\$y = 10^(a^(b)) dot c\$"
        @test M.mlxtran_to_typst("EQUATION:\nz = -(a - b)") == "\$z = -(a - b)\$"
    end

    @testset "ode derivative" begin
        @test M.mlxtran_to_typst("EQUATION:\nddt_I = beta*T*I - dI*I") ==
              "\$(dif I)/(dif t) = beta dot T dot I - \"dI\" dot I\$"
    end

    @testset "calls and power" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = log10(max((r*I*2), 0.001)) + 10^(T0)") ==
              "\$y = log_10(max(r dot I dot 2, 0.001)) + 10^(\"T0\")\$"
    end

    @testset "identifier prettification" begin
        @test M.mlxtran_to_typst("EQUATION:\nT_0 = 1") == "\$T_0 = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nbeta_prime_exp = 1") == "\$beta_(\"prime,exp\") = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nlambda = 1") == "\$lambda = 1\$"
    end

    @testset "camelcase greek peeling" begin
        @test M.mlxtran_to_typst("EQUATION:\nalphaE = 1") == "\$alpha_E = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nthetaE = 1") == "\$theta_E = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nlambdaEstr = 1") == "\$lambda_(\"Estr\") = 1\$"
        @test M.mlxtran_to_typst("EQUATION:\nomega1 = 1") == "\$omega_1 = 1\$"
        # a lowercase suffix is not a camelCase boundary: no false peel
        @test M.mlxtran_to_typst("EQUATION:\nbetas = 1") == "\$\"betas\" = 1\$"
    end

    @testset "division and greek subscript" begin
        @test M.mlxtran_to_typst("EQUATION:\ny = a/(theta_E + I)") ==
              "\$y = (a)/(theta_E + I)\$"
    end

    @testset "multiple equations" begin
        src = "EQUATION:\ny = a + b\nddt_x = -k*x"
        @test M.mlxtran_to_typst(src) == "\$y = a + b\$\n\$(dif x)/(dif t) = -k dot x\$"
    end
end
